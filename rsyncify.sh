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

# set up a persistant ssh connection for rsync to use so:
# - no need to wait for rsync to (re)connect whenever its used
# - only need to authenticate once, no password prompts beyond here
mkdir -p ~/.ssh/ctl
# n: stdin from /dev/null, N: do not execute remote cmd, f: go to background
ctrl_path="$HOME/.ssh/%L-%r@%h:%p" 
ssh -nNf \
	-o ControlPersist=yes \
	-o ControlMaster=yes \
	-o ControlPath=$ctrl_path \
	$HOST

ssh_cmd="ssh -o ControlPath=$ctrl_path"
# echo "$ssh_cmd"
# cmd=$(echo "fd --type f \"$regex\" . | rsync \
# 	--rsh="$ssh_cmd" \
# 	--relative \
# 	--verbose \
# 	--files-from=- . $HOST:$REMOTE_DIR")

fd --type f \"$regex\" . | rsync \
	--rsh="$ssh_cmd" \
	--relative \
	--verbose \
	--files-from=- . $HOST:$REMOTE_DIR

# while sleep 2; do
# 	fd --type f "$regex" . | entr -ds "$cmd"
# done

