#!/bin/bash
#set -x

name=${1:-}  # shellcheck disable=SC2034
target=${2:-}
prio=${3:-}
shift 3

declare -A gateways
for addr in "$@"; do
  gateways[$addr]=$(
    ip -4 -o route get "$addr" |
    grep -Eo '(via|src) ([^ ]+)' |
    head -1 |
    cut -c5-)
done

retval=1
lead=$(fping -a -r1 "$@" | head -1)
if [ -n "$lead" ]; then
    gw1=${gateways[$lead]}
    #echo "$(date) radd $target $gw1 $prio" >>/tmp/ping
    ip -4 route repl "$target" via "$gw1" prio "$prio"
    retval=0
fi

for addr in "$@"; do
  if [ "$addr" != "$lead" ]; then
    gw=${gateways[$addr]}
    #echo "$(date) rdel $target $gw $prio" >>/tmp/ping
    ip -4 route del "$target" via "$gw" prio "$prio" 2>/dev/null
  fi
done

#echo "$(date) ping $retval $target $gw1" >>/tmp/ping
exit $retval
