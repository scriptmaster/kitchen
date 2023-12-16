/**
 * Kitchen: sync / rsync / watchexec program that runs a command on source or text file modification. Ignores common binary extensions and common binary/package dirs.
 */
import time
import os
import log
import vmon

const (
	version = "v1.0.0"
	pwd := os.abs_path('.')
  extensions := ['v', 'sh', 'txt', 'md', 'c', 'py', 'html', 'css', 'js', 'ts', 'java', 'jsx', 'tsx', 'ini', 'json', 'yaml', 'toml', 'csv', 'tsv']
  exclude := ['bin', 'obj', 'out', 'node_modules', 'artifacts', '_*', '.*',  'thirdparty']
)

@[console]
fn main() {
	println('')
	println("✨✨✨ kitchen: Sync remote files / dev env (rsync alt) ✨✨✨\n")
	println("version: $version")
	println('')
}
