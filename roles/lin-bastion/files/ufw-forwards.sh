#!/bin/bash
set -euo pipefail
#set -x

CONFIG=/etc/network/ufw-forwards
LABEL="ufw-forwards"
OPENVZ="${OPENVZ:-false}"

stop()
{
    /sbin/iptables-save  | grep -v "$LABEL" | /sbin/iptables-restore
    /sbin/ip6tables-save | grep -v "$LABEL" | /sbin/ip6tables-restore
}

start()
{
  # shellcheck disable=SC2034 (qname unused)
  while read -r ipver mark sport dport saddr daddr qname; do
    case "$ipver" in
      ipv4)
        iptables=/sbin/iptables
        daddr_to="$daddr"
        ;;
      ipv6)
        iptables=/sbin/ip6tables
        daddr_to="[$daddr]"
        # forwarding requires IPv6 table NAT, which is absent on OpenVZ
        [[ $OPENVZ = false ]] || continue
        ;;
      ''|'#'*)
        continue
        ;;
      *)
        echo "invalid IPver '$ipver'" 1>&2
        continue
        ;;
    esac
    #mark="0xf0$(printf '%05d' "$dport")"

    $iptables \
              -t mangle -A PREROUTING \
              -p tcp --syn -d "$saddr" --dport "$sport" \
              -j CONNMARK --set-xmark "$mark" \
              -m comment --comment "$LABEL"
    $iptables \
              -t filter -A FORWARD \
              -p tcp -m connmark --mark "$mark" \
              -j ACCEPT \
              -m comment --comment "$LABEL"
    $iptables \
              -t nat -A PREROUTING \
              -p tcp -m connmark --mark "$mark" \
              -j DNAT --to-destination "$daddr_to:$dport" \
              -m comment --comment "$LABEL"
    $iptables \
              -t nat -A POSTROUTING \
              -p tcp -m connmark --mark "$mark" \
              -j MASQUERADE \
              -m comment --comment "$LABEL"
  done < "$CONFIG"
}

case "${1:-}" in
  stop)
    stop
    ;;
  start|restart|reload)
    stop
    start
    ;;
  *)
    echo "usage: $0 stop|start"
    exit 1
    ;;
esac
exit 0
