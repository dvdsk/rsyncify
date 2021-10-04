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

# while sleep 2; do
	cmd=$(echo "fd --type f \"$regex\" . | rsync --relative --verbose --files-from=- . $HOST:$REMOTE_DIR")
	fd --type f "$regex" . | entr -ds "$cmd"
# done

