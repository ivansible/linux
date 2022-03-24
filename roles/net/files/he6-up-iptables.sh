#!/bin/sh
#set -x
set -e

[ -n "$IF_HE6_NET48" ] || exit 0
[ -n "$IF_HE6_HENET" ] || exit 0

CMNT_6TO4="allow 6to4 on $IFACE"
iptables -w -L INPUT | grep -Fq "/* $CMNT_6TO4 */" || \
iptables -w -I INPUT -p 41 -s "$IF_ENDPOINT" \
            -j ACCEPT -m comment --comment "$CMNT_6TO4"

CMNT_TRR6="allow traceroute6 on $IFACE"
iptables -w -L FORWARD | grep -Fq "/* $CMNT_TRR6 */" || \
iptables -w -I FORWARD -p udp --dport 33434 \
            -j ACCEPT -m comment --comment "$CMNT_TRR6"

CMNT_FWD6="allow ipv6 forwarding on $IFACE"
ipset -exist create mynet6 hash:net family inet6
ip6tables -w -L FORWARD | grep -Fq "/* $CMNT_FWD6 */" || \
ip6tables -w -A FORWARD -m conntrack --ctstate NEW \
             -i "$IFACE" -m set --match-set mynet6 src \
             -j ACCEPT -m comment --comment "$CMNT_FWD6"

ip -6 route replace default from "$IF_ADDRESS"   dev "$IFACE" proto static
ip -6 route replace default from "$IF_HE6_NET48" dev "$IFACE" proto static
ip -6 route replace to "$IF_HE6_HENET" dev "$IFACE" proto static

exit 0
