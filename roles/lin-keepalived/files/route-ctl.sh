#!/bin/bash
#set -x

# shellcheck disable=SC1091
. /etc/default/keepalived

state=${1:-}
name=${2:-}
proto=${3:-}
vip=${4:-}
targets=${5:-}
device=${6:-}
metric=${7:-}

[ "$state" = up ] && cmd=del || cmd=add
for tip in ${targets//,/ }; do
    ip "$proto" route "$cmd" "$tip" via "$vip" metric "$metric"
done

[[ $ROUTER_LOG ]] && echo "$(date) rctl $state $name $vip $device $metric" >> "$ROUTER_LOG"
exit 0
