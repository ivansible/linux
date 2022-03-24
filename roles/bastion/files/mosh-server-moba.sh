#!/bin/bash
# mosh helper for mobaxterm
# ansible-managed
# goal: fix arguments: remove "-s" any trailing "new"
fixargs=()
for arg in "$@"; do
    case "$arg" in
        -s)  continue ;;
        ...) break ;;
        *)   fixargs+=("$arg") ;;
    esac
done
#echo "mosh-server: '$@' --> '${fixargs[@]}'"
exec mosh-server "${fixargs[@]}"
