#!/bin/bash
#set -x
set -e
if [[ $IF_HE6_NET48 ]] && [[ $IF_HE6_HENET ]]; then
    ip -6 route replace default from "$IF_ADDRESS"   dev "$IFACE" proto static
    ip -6 route replace default from "$IF_HE6_NET48" dev "$IFACE" proto static
    ip -6 route replace to "$IF_HE6_HENET" dev "$IFACE" proto static
fi
if [[ $IF_HE6_LOOPIP ]] && [[ $IF_HE6_NET48 ]]; then
    ip -6 addr replace "${IF_ADDRESS%%::*}::${IF_HE6_LOOPIP}"   dev lo:2
    ip -6 addr replace "${IF_HE6_NET48%%::*}::${IF_HE6_LOOPIP}" dev lo:2
fi
exit 0
