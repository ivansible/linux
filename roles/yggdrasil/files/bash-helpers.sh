yc-peers() {
  local db=~/.local/bashrc/yggdrasil.db
  local verb=0
  local sid sip nid nip peers

  [[ ${1:-} = -v ]] && verb=1 && shift 1
  local name=${1:?}

  case "$name" in
    local)
      yggdrasilctl -json getPeers |
        jq -r '.peers | to_entries[] | [.key, .value.remote] | @tsv' |
        sort
      return
      ;;
    db)
      sort "$db"
      return
      ;;
  esac

  sid=$(awk '($1=="'"$name"'"){print$3}' "$db")
  if [ -z "$sid" ]; then
    sid=$name
    name=nil
  fi

  if [[ $verb = 1 ]]; then
    trap "set +x" INT
    set -x
  fi

  sip=$(yggdrasilctl getNodeInfo key="$sid" | jq -r "keys[]" 2>/dev/null)
  sip=${sip:-notfound}
  printf '%-9s  %-64s  %-38s\n' "$name" "$sid" "$sip"
  printf '%-9s..%-64s..%-38s\n' "" "" "" | tr " ." "- "
  peers=$(yggdrasilctl debug_remoteGetPeers key="$sid" | jq -r ".[].keys[]" 2>/dev/null)
  for nid in $peers; do
    nip=$(yggdrasilctl getNodeInfo key="${nid}" | jq -r "keys[]" 2>/dev/null)
    nip=${nip:-"xxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx"}
    name=$(awk "/$nid/{print\$1}" "$db")
    name=${name:-nil}
    printf '%-9s  %-64s  %-38s\n' "$name" "$nid" "$nip"
  done  # | LC_ALL=C sort -t: -k8
  [[ $verb = 0 ]] || set +x
}
