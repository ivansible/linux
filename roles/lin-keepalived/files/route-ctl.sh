#!/bin/bash
#set -x

state=${1:-}
name=${2:-}
proto=${3:-}
vip=${4:-}
targets=${5:-}
device=${6:-}
metric=${7:-}
debug=0

[ "$state" = up ] && cmd=del || cmd=add
for tip in ${targets//,/ }; do
    ip "$proto" route "$cmd" "$tip" via "$vip" metric "$metric"
done

[ $debug = 0 ] || echo "$(date) rctl $state $name $vip $device $metric" >>/tmp/ping
exit 0
