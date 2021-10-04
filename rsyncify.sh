#!/usr/bin/env bash
set -e

# watches for file and dir changes that follow a pattern then pushes 
# the updates to a remote server
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
ctrl_path="$HOME/.ssh/%L-%r@%h:%p" 
# n: stdin from /dev/null, N: do not execute remote cmd, f: go to background
# controlmaster=auto: reuse existing ssh open session if availible otherwise
# master, if the other session closes ends this ssh session will keep the
# connection going
ssh -nNf \
	-o ControlPersist=yes \
	-o ControlMaster=auto \
	-o ControlPath=$ctrl_path \
	$HOST

ssh_cmd="ssh -o ControlPath=$ctrl_path"
cmd=$(echo "fd --type f \"$regex\" . | rsync \
	--rsh=\"$ssh_cmd\" \
	--relative \
	--files-from=- \
	. $HOST:$REMOTE_DIR")

# this will run rsync once then wait for changes in the watched files
# and the directories they are in (thanks to entr -d). On change in dir
# the watched files list is updated
while true; do
	fd --type f "$regex" . | entr -ds "$cmd" || true
done

