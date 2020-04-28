#!/bin/sh
#set -x
set -e
if [ -n "$IF_HE6_NET48" ] && [ -n "$IF_HE6_HENET" ]; then
    ip -6 route replace default from "$IF_ADDRESS"   dev "$IFACE" proto static
    ip -6 route replace default from "$IF_HE6_NET48" dev "$IFACE" proto static
    ip -6 route replace to "$IF_HE6_HENET" dev "$IFACE" proto static
fi
exit 0
