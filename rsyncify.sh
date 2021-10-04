#!/usr/bin/env bash
set -e

# watches for file changes then pushes the updates to a remove 
# server
# dependencies: entr, fd 

HOST=dpsdas
REMOTE_DIR=mock-fs

# individual regex patterns of files that should be watched
patterns=(
 ".*\.sh"
 ".*\.c"
 ".*\.cpp"
 ".*\.toml"
 ".*\.rs"
 "makefile"
)

regex=""
for p in ${patterns[@]}; do
	regex="$regex$p|"
done
regex="(${regex::-1})"
files=($(fd --type f "$regex" .))

# on server side, detect changes and run cmd
#   - possibly just watch a .sync file?

function min() {
	echo $(($1>$2 ? $2 : $1))
}

function dispatch_watcher() {
	echo $@ | entr -rc "rsync"
}

n_files=${#files[@]}
n_watchers=$(min 4 $n_files)
chunk_size=$(($n_files / $n_watchers))

for i in $(seq 0 $(($n_watchers-2))); do
	start=$(($i * $chunk_size))
	dispatch_watcher "${files[@]:$start:$chunk_size}"
done
# last group takes every file till the end
start=$(($i * $chunk_size + $chunk_size))
dispatch_watcher "${files[@]:$start}"
