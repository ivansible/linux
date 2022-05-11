#!/bin/bash
#set -x
set -e

[[ $IF_HE6_HENET ]] || exit 0

ip   -6 route replace           to "$IF_HE6_HENET" dev "$IFACE" proto static
ip   -6 route replace default from "$IF_ADDRESS"   dev "$IFACE" proto static
if [[ $IF_HE6_NET64 ]]; then
  ip -6 route replace default from "$IF_HE6_NET64" dev "$IFACE" proto static
fi
if [[ $IF_HE6_NET48 ]]; then
  ip -6 route replace default from "$IF_HE6_NET48" dev "$IFACE" proto static
fi

[[ $IF_HE6_LOOPIP ]] || exit 0

ip   -6 addr replace "${IF_ADDRESS%%::*}::${IF_HE6_LOOPIP}"   dev lo:2
if [[ $IF_HE6_NET64 ]]; then
  ip -6 addr replace "${IF_HE6_NET64%%::*}::${IF_HE6_LOOPIP}" dev lo:2
fi
if [[ $IF_HE6_NET48 ]]; then
  ip -6 addr replace "${IF_HE6_NET48%%::*}::${IF_HE6_LOOPIP}" dev lo:2
fi

exit 0
