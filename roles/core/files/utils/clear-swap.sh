#!/bin/bash
[ $(id -u) = 0 ] || \
exec sudo "$0" "$@" || exit 1
set -x
size=400M
test -e /reswap && exit 1
free -h
fallocate -l $size /reswap
chmod 600 /reswap
mkswap /reswap >/dev/null
swapon /reswap
swapoff /swapfile
swapon /swapfile
swapoff /reswap
rm /reswap
free -h
