#!/bin/bash
#set -x

prog_path="$(readlink -f "$0")"
prog_name="$(basename "$prog_path")"
prog_dir="$(dirname "$prog_path")"
ovpn_dir="$(dirname "$prog_dir")"
easyrsa_dir="${ovpn_dir}/easy-rsa"

force='false'
help='false'

while true; do
  case "$1" in
    -f | --force)
      force=true; shift 1 ;;
    -*)
      help=true;  shift 1 ;;
    *)
      break ;;
  esac
done

server="${1:-}"
client="${2:-}"
cname="$client"

if [ "$help" = 'true' ] || [ -z "$server" ] || [ -z "$client" ]; then
    echo "usage: ${prog_name} [-f] SERVER CLIENT"
    exit 1
fi

srv_dir="${ovpn_dir}/servers/${server}"
tpl_file="${srv_dir}/template.ovpn"

cli_dir="${srv_dir}/clients"
crt_file="${cli_dir}/${client}.crt"
key_file="${cli_dir}/${client}.key"
cfg_file="${cli_dir}/${client}.ovpn"

cd "$ovpn_dir" || exit 1

if [ ! -f "$tpl_file" ] || [ ! -d "$cli_dir" ]; then
    echo "server not found: ${server}"
    # shellcheck disable=SC2012,SC2035
    servers=$(ls -1 *.conf 2>/dev/null | sed -e 's/[.]conf$//g')
    # shellcheck disable=SC2116,SC2086
    echo "available servers: $(echo $servers)"
    exit 1
fi

if [ "$force" = 'true' ]; then
    rm -f "$crt_file" "$key_file" "$cfg_file"
fi

if [ -f "$crt_file" ] || [ -f "$key_file" ] || [ -f "$cfg_file" ]; then
    echo "client already exists: ${client}"
    exit 1
fi

cd "$easyrsa_dir" || exit 1

rm -f "./pki/issued/${cname}.crt"
rm -f "./pki/private/${cname}.key"
rm -f "./pki/reqs/${cname}.req"

export EASYRSA_CERT_EXPIRE=3650
./easyrsa build-server-full "$cname" nopass || exit 1

cp -f "./pki/issued/${cname}.crt" "${crt_file}"
cp -f "./pki/private/${cname}.key" "${key_file}"

# strip comments from certificate
crt=$(awk '/---BEGIN/{body=1} (body){print}' "$crt_file")
key=$(cat "$key_file")

# substitute cert/key into template
script='/^CLIENT_CRT/{print crt;next} /^CLIENT_KEY/{print key;next} {print}'
awk -v crt="$crt" -v key="$key" "$script" < "$tpl_file" | \
    sed -r -e "s|CLIENT_NAME|${client}|g" > "$cfg_file"

chmod 600 "$crt_file" "$key_file"
chmod 644 "$cfg_file"

touch "${srv_dir}/configs/${client}"

echo "OK"
