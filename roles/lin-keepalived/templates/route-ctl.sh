#!/bin/bash
state=${1:-}
name=${2:-}
iface=${3:-}
target=${4:-}
vip=${5:-}
prio=${6:-}
case "$state" in
  up)
    ip route del "$target" via "$vip" prio "$prio"
    ;;
  down)
    ip route add "$target" via "$vip" prio "$prio"
    ;;
esac
