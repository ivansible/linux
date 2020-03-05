#!/bin/bash
[ $(id -u) = 0 ] || \
exec sudo "$0" "$@" || exit 1
set -x
df -m /
journalctl --disk-usage
journalctl --vacuum-size 10M
apt-get -qy autoremove
apt-get -qy clean
rm -f /var/log/*.[1-9]{,.gz} \
      /var/log/*/*.[1-9]{,.gz} \
      /var/log/nginx/*.log.*.gz
df -m /
