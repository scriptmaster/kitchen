# kitchen
Kitchen: sync / rsync / watchexec program that runs a command on source or text file changes. Ignores common binary extensions and common binary/package dirs.

Written in pure v (with vmon dependency, a C wrapper for dmon, file watcher)

## Usage 

`kitchen "rsync . yourhost.com"`

`kitchen "rsync . yourhost.com" -p "ssh yourhost.com systemctl restart web.service"`

`kitchen -scp yourhost.com`

`kitchen -e md,mdx,mmd ./build.sh`

## Installation
`v install scriptmaster.kitchen`

or

`v install https://github.com/scriptmaster/kitchen`

#### 2. Install to /usr/local/bin/

`v install https://github.com/scriptmaster/kitchen && v -o /usr/local/bin/kitchen ~/.vmodules/kitchen`

### Extensions
```
extensions := ['v', 'sh', 'txt', 'md', 'c', 'cs', 'go', 'py', 'html', 'css', 'js', 'ts', 'java', 'jsx', 'tsx', 'ini', 'json', 'yaml', 'toml', 'csv', 'tsv']
```

### Exclude
```
exclude := ['bin', 'obj', 'out', 'node_modules', 'artifacts', 'thirdparty', '_*', '.*']
```

### Dependencies
vmon

#### Inspiration

watchexec (from rust)
