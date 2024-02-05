/**
 * Kitchen: sync / rsync / watchexec program that runs a command on source or text file modification. Ignores common binary extensions and common binary/package dirs.
 */
import time
import os
import log
import v.vmod
import vmon
import cli { Command, Flag }

const (
	// name = 'kitchen'
	// version = "v1.0.2"
	// logo = "✨✨✨ Kitchen ✨✨✨"
	// description = "$logo\nkitchen runs a command upon file modifications (transfers the modified watched file, if you provide -scp) and also runs multiple post commands, if you provide one or more -p commands.\n\nEssentially, a watchexec program that runs a command on source or text file modification. Ignores common binary extensions and dirs."
	mod = vmod.decode( @VMOD_FILE ) or { panic('v.mod decode error: $err') }
	cwd := os.abs_path('.')
	extensions := 'v,sh,vsh,vv,txt,md,mdx,mmd,c,cs,go,py,html,css,js,mjs,ts,java,jsx,tsx,ini,json,jsonc,yaml,toml,csv,tsv,mojo,Makefile,Dockerfile'
	excludes := 'bin,obj,out,node_modules,artifacts,thirdparty,.git,_*,.*'
)

@[console]
fn main() {
	mut cmd := Command{
		name: mod.name
		description: "Version ${mod.version}\n-------------\n${mod.description}"
		version: mod.version
		usage: "command_to_run_on_file_change.sh"
		execute: kitchen
	}

	cmd.add_flag(Flag{
		name: 'ext'
		flag: .string
		abbrev: 'e'
		default_value: [extensions]
		description: 'Comma separated list of extensions'
	})

	cmd.add_flag(Flag{
		name: 'exclude'
		flag: .string
		abbrev: 'x'
		default_value: [excludes]
		description: 'Comma separated list of file and folder exclusions'
	})

	cmd.add_flag(Flag{
		name: 'scp'
		flag: .string
		abbrev: 's'
		description: 'scp options: e.g., -scp root@domain.com:/usr/local/src/project/ copies \$0/\$1 to the given host,\n\twhere \$0 is cwd, \$1 is the modified file path.'
	})

	cmd.add_flag(Flag{
		name: 'post_cmd'
		flag: .string_array
		abbrev: 'p'
		description: 'post command to exec. e.g., "echo done >> done.log" Multple commands -p can be given, those will be run in parallel.'
	})

	cmd.add_flag(Flag{
		name: 'deploy'
		flag: .string
		abbrev: 'd'
		description: 'deploy command to exec upon pressing enter. e.g., "echo done >> done.log"'
	})

	//cmd.add_default_flags()
	cmd.setup()
	cmd.parse(os.args)
}

fn kitchen(cmd Command) ! {
	log.info('${mod.name} started: ${time.now()}')

	mut config := new_config()
	config.exts = (cmd.flags.get_string('ext') or { extensions }).split(',').map(it.trim(' '))
	config.excludes = (cmd.flags.get_string('exclude') or { excludes }).split(',').map(it.trim(' '))

	config.scp = cmd.flags.get_string('scp') or { '' } // if scp_options_user_host_path contains 'scp scp_options_user_host_path $filename'
	config.deploy = cmd.flags.get_string('deploy') or { '' }
	// config.cmd = cmd.flags.get_string('cmd') or { '' } // if scp_options_user_host_path contains 'scp scp_options_user_host_path $filename'
	config.post_cmd = cmd.flags.get_strings('post_cmd') or { [''] } // if scp_options_user_host_path contains 'scp scp_options_user_host_path $filename'

	config.cmd = if cmd.args.len > 0 { cmd.args[0] } else { '' }

	flags := u32(vmon.WatchFlag.recursive) | u32(vmon.WatchFlag.follow_symlinks)
	vmon.watch(cwd.trim_right('/'), watch_callback, flags, config) or { panic(err) }

	for {
		inp := os.input('')
		match inp {
			'exit', 'exit()', ':q', ':wq', 'quit', 'break' {
				break
			}
			'' {
				if config.deploy != '' {
					// println('deploy cmd: ${config.deploy}')
					exec(config.deploy, cwd, '')
				}
			}
			else {
				file_modified(cwd, '', mut config) or {
					log.error('Error in file modified')
				}
			}
		}
	}
}

fn watch_callback(watch_id vmon.WatchID, action vmon.Action, root_path string, file_path string, old_file_path string, user_data voidptr) {
	if isnil(user_data) {
		log.debug('user_data is nil')
		return
	}

	mut config := unsafe { &Config(user_data) }
	if isnil(config) {
		log.debug('config is nil')
		return
	}

	$if trace ? {
		log.info('watch[$watch_id]: $action $file_path in $root_path, $config')
	} $else {
		log.info('watch[$watch_id]: $action $file_path in $root_path')
	}

	match action {
		.modify {
			file_modified(root_path, file_path, mut config) or {
				log.error('Error in file modified')
			}
		}
		else {
			// 
		}
	}
}

fn file_modified(root_path string, file_path string, mut config Config) !bool {
	config.cycle++
	match config.memoized_paths[file_path] {
		.free {
			config.memoized_paths[file_path] = .memoized
		}
		.memoized {
			log.info('scheduling: $file_path')
			config.memoized_paths[file_path] = .scheduled
		}
		.scheduled {
			println('already scheduled: $file_path')
			return false // cannot continue if already scheduled to run in a while
		}
	}

	$if trace ? {
		println('config: $config')
	}
	config.file_path = file_path // memoization

	file_name := file_path.all_after_last('/') //test:
	paths := file_path.split('/') //test: 

	// if ((file_name.contains('.') && config.exts.any(file_path.ends_with('.'+it))) || (file_name in config.exts)) &&
	// 	!paths.any(it.starts_with('.')) && !paths.any(it.starts_with('_')) &&
	// 		!config.excludes.any(it in paths)
	// {
	if (file_name.contains('.') && config.exts.any(file_path.ends_with('.'+it))) &&
		!paths.any(it.starts_with('.')) && !paths.any(it.starts_with('_')) &&
			!config.excludes.any(it in paths)
	{
		if config.cmd != '' {
			exec(config.cmd, root_path, file_path)
		}

		if config.scp != '' {
			root := root_path.trim_right('/')
			if config.scp.starts_with('scp ') {
				if config.scp.contains('\$0') || config.scp.contains('\$1') {
					exec(config.scp, root, file_path)
				} else {
					exec('scp \$0/\$1 ${config.scp[4..].trim_right("/")}', root, file_path)
				}
			} else if config.scp.contains('\$0') || config.scp.contains('\$1') {
				exec('scp ${config.scp}', root, file_path)
			} else {
				exec('scp \$0/\$1 ${config.scp.trim_right("/")}/\$1', root, file_path)
			}
		}

		if config.post_cmd.len > 0 {
			for post_cmd in config.post_cmd {
				exec(post_cmd, root_path, file_path)
			}
		}
	} else {
		log.info('Skipped $file_path')
	}

	log.info('Done: $file_path')
	time.sleep(10 * time.millisecond)

	config.file_path = ''
	config.memoized_paths[file_path] = .free

	return true
}

fn exec(cmd string, root_path string, file_path string) {
	command := cmd.replace('\$0', root_path).replace('\$1', file_path)
	// $if trace ? {
	log.info('command: $command')
	// }
	os.execute(command)
}

enum MemoizationState as u8 {
	free
	memoized
	scheduled
}

struct Config {
mut:
	cycle int
	file_path string
	memoized_paths map[string]MemoizationState

	exts []string
	excludes []string

	scp string
	cmd string
	post_cmd []string
	deploy string
}

fn new_config() Config {
	return Config{}
}
