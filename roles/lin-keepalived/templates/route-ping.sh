#!/bin/bash
#set -x

name=${1:-}  # shellcheck disable=SC2034
proto=${2:-}
target=${3:-}
prio=${4:-}
shift 4

declare -A gateways
for addr in "$@"; do
  gateways[$addr]=$(
    ip "$proto" -o route get "$addr" |
    grep -Eo 'dev [^ ]+' |
    head -1 |
    cut -c5-)
done

retval=1
[ "$proto" = '-6' ] && pinger=fping6 || pinger=fping
lead=$($pinger -a -r1 "$@" | head -1)
if [ -n "$lead" ]; then
    gw1=${gateways[$lead]}
    #echo "$(date) radd $target $gw1 $prio" >>/tmp/ping
    ip "$proto" route replace "$target" dev "$gw1" prio "$prio" 2>/dev/null
    retval=0
fi

for addr in "$@"; do
  if [ "$addr" != "$lead" ]; then
    gw=${gateways[$addr]}
    #echo "$(date) rdel $target $gw $prio" >>/tmp/ping
    ip "$proto" route delete "$target" dev "$gw" prio "$prio" 2>/dev/null
  fi
done

#echo "$(date) ping $retval $target $gw1" >>/tmp/ping
exit $retval
