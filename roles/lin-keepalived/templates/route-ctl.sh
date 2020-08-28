#!/bin/bash
#set -x

state=${1:-}
name=${2:-}   # shellcheck disable=SC2034
iface=${3:-}  # shellcheck disable=SC2034
target=${4:-}
vip=${5:-}
prio=${6:-}

case "$state" in
  up)
    ip route del "$target" via "$vip" prio "$prio"
    ;;
  dn)
    ip route add "$target" via "$vip" prio "$prio"
    ;;
esac

#echo "$(date) -- $? $state $target $vip $prio" >>/tmp/ping
exit 0
