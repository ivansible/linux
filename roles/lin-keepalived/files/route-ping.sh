#!/bin/bash
#set -x

name=${1:-}
beacons=${2:-}
targets4=${3:-}
targets6=${4:-}
metric=${5:-}
debug=0

beacons=${beacons//,/ }
targets4=${targets4%-}
targets4=${targets4//,/ }
targets6=${targets6%-}
targets6=${targets6//,/ }

declare -A devices
for bip in $beacons; do
  devices[$bip]=$(
    ip -4 -o route get "$bip" |
    grep -Eo 'dev [^ ]+' |
    head -1 |
    cut -c5-)
done

retval=1
# shellcheck disable=SC2086
leader=$(fping -a -r1 $beacons | head -1)
if [ -n "$leader" ]; then
    retval=0
    dev=${devices[$leader]}
    [ $debug = 0 ] || echo "$(date) radd $name $dev $metric" >>/tmp/ping
    for tip in $targets4; do
        ip -4 route replace "$tip" dev "$dev" metric "$metric" 2>/dev/null
    done
    for tip in $targets6; do
        ip -6 route replace "$tip" dev "$dev" metric "$metric" 2>/dev/null
    done
fi

for bip in $beacons; do
    [ "$bip" = "$leader" ] && continue
    dev=${devices[$bip]}
    [ $debug = 0 ] || echo "$(date) rdel $name $dev $metric" >>/tmp/ping
    for tip in $targets4; do
        ip -4 route delete "$tip" dev "$dev" metric "$metric" 2>/dev/null
    done
    for tip in $targets6; do
        ip -6 route delete "$tip" dev "$dev" metric "$metric" 2>/dev/null
    done
done

exit $retval
