#!/bin/sh
exec /bin/mount -t ecryptfs -i "$@"
