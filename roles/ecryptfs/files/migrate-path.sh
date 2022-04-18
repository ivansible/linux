#!/bin/bash
#set -x
set -e
path=${1:?}
test -d "$path" || mkdir -p "$path"
path=$(realpath "$path")
orig=$(mktemp -d "$path.migrate.XXXXXXXX")
rsync -a --delete "$path/" "$orig/"
mount "$path"
rm -rf "${path:?}"/{,.[^.],.??}*
rsync -av --delete "$orig/" "$path/"
rm -rf "$orig"
echo "SUCCESS $path"
