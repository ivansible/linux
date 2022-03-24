#!/bin/bash
#set -x

ferm_dir="{{ ferm_dir }}"
ferm_bindir="{{ ferm_bindir }}"
ferm_binary="{{ ferm_binary }}"
ferm_config="{{ ferm_dir }}/config.ferm"
ferm_nofork="{{ ferm_nofork }}"
ferm_lib_nolock="{{ ferm_lib_nolock }}"
ferm_openvz_file="{{ ferm_openvz_file }}"
ferm_ipset_files="{{ ferm_ipset_files |join(',') }}"

# shellcheck disable=SC2086
[[ $FERM_NOLOCK ]] || \
exec /usr/bin/flock $ferm_nofork /run/xtables.lock \
/usr/bin/env FERM_NOLOCK=1 "$0" "$@"

## prevent iptables locking below this line
export LD_PRELOAD=$ferm_lib_nolock

case "${1:-}" in
  --reset)
    shift 1
    FERM_RESET=1
    ;;
  --condreset)
    shift 1
    /sbin/iptables -C FORWARD -j _FORWARD 2>/dev/null
    FERM_RESET=$?
    ;;
  *)
    FERM_RESET=0
    [ -e "$ferm_dir/RESET" ] && FERM_RESET=1
    ;;
esac

if [ -e /proc/vz ]; then
    ## setup host/port multi-lists
    FERM_VZ_DEFS=$("$ferm_bindir/ferm-openvz" -c "$ferm_dir" -l "$ferm_ipset_files" -o "$ferm_openvz_file" -O)
    FERM_VZ=1
else
    ## setup host/port ipsets
    "$ferm_bindir/ferm-ipset" -c "$ferm_dir" -l "$ferm_ipset_files"
    FERM_VZ=0
fi

export FERM_RESET FERM_VZ FERM_VZ_DEFS

get_chains() {
    local domain=$1 table=$2 prefix=$3
    "/sbin/$domain" -t "$table" -S |
    awk '/^-N '"$prefix"'-/{print $2}' |
    grep -Ev -- '-USER' ||:
}

KUBE_CHAINS_NAT4=$(get_chains iptables nat KUBE)
CNI_CHAINS_NAT4=$(get_chains iptables nat CNI)
CNI_CHAINS_FILTER4=$(get_chains iptables filter CNI)
export KUBE_CHAINS_NAT4 CNI_CHAINS_NAT4 CNI_CHAINS_FILTER4

# shellcheck disable=SC2046
export $(grep -Ev ^# /etc/default/ferm 2>/dev/null) >/dev/null

exec "$ferm_binary" "$@" "$ferm_config"
