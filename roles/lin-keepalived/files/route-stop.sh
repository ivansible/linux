#!/bin/bash
#set -x

# shellcheck disable=SC1091
. /etc/default/keepalived

for proto in -4 -6; do
    ip "$proto" route show |
    grep -E "metric (${ROUTER_METRIC_GW}|${ROUTER_METRIC_VIP})( |\$)" |
    while read -r route; do
        # shellcheck disable=SC2086
        ip "$proto" route delete $route 2>/dev/null
        [[ $ROUTER_LOG ]] && echo "$(date) rstp $proto $route" >> "$ROUTER_LOG"
    done
done

exit 0
