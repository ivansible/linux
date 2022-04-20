#!/bin/bash
#set -x
set -euo pipefail
export PATH=/bin:/usr/bin
pf="${1:?}"
[[ $pf != - ]] || pf="${PHRASE:--}"
if [[ $pf = - ]]; then
    url=${2:?}
    [[ $url != - ]] || url="${PF_URL:--}"
    if base64 -d <<< "$url" &>/dev/null; then  url=$(base64 -d <<< "$url"); fi
    pf=$(curl -sL "$url" |grep -o "${3:?}.*${4:?}" |sha256sum |awk '{print $1}')
fi
ecryptfs-add-passphrase - <<< "$pf"
