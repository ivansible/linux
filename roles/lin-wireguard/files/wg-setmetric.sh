#!/bin/bash
#set -x
set -euo pipefail

dev=${1:-}
metric=${2:-}

if [ -z "$dev" ] || [ -z "$metric" ]; then
    echo "usage: $(basename "$0") DEVICE METRIC"
    exit 1
fi

if [ "$metric" = 0 ]; then
    exit 0
fi

for proto in -4 -6; do
    ## TODO handle routing tables and policy routing
    /sbin/ip -o "$proto" route show dev "$dev" | \
    while read route; do
        if [ "$route" = "${route/metric/}" ]; then
            # shellcheck disable=SC2086
            /sbin/ip "$proto" route del $route dev "$dev"
            # shellcheck disable=SC2086
            /sbin/ip "$proto" route add $route metric "$metric" dev "$dev"
            continue
        fi
        route_new=$(echo "$route" | sed -r -e "s/metric [0-9]+/metric $metric/")
        if [ "$route" != "$route_new" ]; then
            # shellcheck disable=SC2086
            /sbin/ip "$proto" route del $route dev "$dev"
            # shellcheck disable=SC2086
            /sbin/ip "$proto" route add $route_new dev "$dev"
        fi
    done
done
