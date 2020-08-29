#!/bin/bash
#set -x

state=${1:-}
name=${2:-}   # shellcheck disable=SC2034
dev=${3:-}    # shellcheck disable=SC2034
proto=${4:-}
target=${5:-}
vip=${6:-}
prio=${7:-}

case "$state" in
  up)
    ip "$proto" route del "$target" via "$vip" prio "$prio"
    ;;
  dn)
    ip "$proto" route add "$target" via "$vip" prio "$prio"
    ;;
esac

#echo "$(date) -- $? $state $target $vip $prio" >>/tmp/ping
exit 0
