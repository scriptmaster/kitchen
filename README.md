# kitchen
Kitchen: sync / rsync / watchexec program that runs a command on source or text file changes. Ignores common binary extensions and common binary/package dirs.

Written in pure v (with vmon dependency, a C wrapper for dmon, file watcher)

## Usage 

`kitchen -scp yourhost.com`

`kitchen -e md,mdx,mmd ./build.sh`

## Installation
`v install kitchen`

or

`v install https://github.com/scriptmaster/kitchen`


### Extensions
```
extensions := ['v', 'sh', 'txt', 'md', 'c', 'py', 'html', 'css', 'js', 'ts', 'java', 'jsx', 'tsx', 'ini', 'json', 'yaml', 'toml', 'csv', 'tsv']
```

### Exclude
```
exclude := ['bin', 'obj', 'out', 'node_modules', 'artifacts', 'thirdparty', '_*', '.*']
```

### Dependencies
vmon

#### Inspiration

watchexec (from rust)
