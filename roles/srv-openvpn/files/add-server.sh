#!/bin/bash
#set -x

prog_path="$(readlink -f "$0")"
prog_name="$(basename "$prog_path")"
prog_dir="$(dirname "$prog_path")"
ovpn_dir="$(dirname "$prog_dir")"
easyrsa_dir="${ovpn_dir}/easy-rsa"
tmpl_dir="${ovpn_dir}/templates"

default_port=1194
default_proto=udp
default_cname=$(hostname)

srv_name=""
cname=""
domain=""
port=""
proto=""
addr=""
subnet4=""
subnet6=""
force=false
help=false

while true; do
  case "$1" in
    -f | --force)   force=true;   shift 1 ;;
    -4 | --subnet4) subnet4="$2"; shift 2 ;;
    -6 | --subnet6) subnet6="$2"; shift 2 ;;
    -p | --port)    port="$2";    shift 2 ;;
    -t | --tcp)     proto=tcp;    shift 1 ;;
    -u | --udp)     proto=udp;    shift 1 ;;
    -P | --proto)   proto="$2";   shift 2 ;;
    -a | --addr)    addr="$2";    shift 2 ;;
    -d | --domain)  domain="$2";  shift 2 ;;
    -c | --cname)   cname="$2";   shift 2 ;;
    -*)             help=true;    shift 1 ;; # unknown option
    "")
      break ;;
    *)
      [ -z "$cname" ] || help=true  # duplicate option
      [ -z "$srv_name" ] && srv_name="$1" || cname="$1"
      shift ;;
  esac
done

if [ -z "$cname" ] && [ -n "$domain" ]; then
    cname="${srv_name}.${domain}"
fi

port=${port:-$default_port}
proto=${proto:-$default_proto}
cname=${cname:-$default_cname}

case "$proto" in
    tcp | udp )  ;;
    *) help=true ;;
esac

if [ "$help" = 'true' ] || [ -z "$srv_name" ] || [ -z "$subnet4" ]; then
    [ -n "$srv_name" ] || echo "server name is required"
    [ -n "$subnet4" ] || echo "subnet4 is required"
    echo "usage: ${prog_name} [options...] SERVER_NAME [COMMON_NAME]"
    echo "options:"
    echo "  -f --force                remove previous server settings, if any"
    echo "  -p --port    PORT         server port, defaults to ${default_port}"
    echo "  -t --tcp                  select protocol tcp"
    echo "  -u --udp                  select protocol udp"
    echo "  -P --proto   tcp|udp      server protocol (defaults to ${default_proto})"
    echo "  -a --addr    SERVER_ADDR  override server ip address"
    echo "  -4 --subnet4 SUBNET/CIDR  select ipv4 subnet (REQUIRED)"
    echo "  -6 --subnet6 SUBNET/CIDR  select ipv6 subnet (optional)"
    echo "  -c --cname   COMMON_NAME  optional, defaults to '${default_cname}'"
    echo "  -d --domain  DOMAIN       set common name to SERVER_NAME.DOMAIN"
    exit 1
fi

subnet4_addr=$(ipcalc "$subnet4" |awk '/^Network/ {print $2}')
subnet4_mask=$(ipcalc "$subnet4" |awk '/^Netmask/ {print $2}')

if [ -z "$subnet4_addr" ] || [ -z "$subnet4_mask" ]; then
    echo "invalid ipv4 subnet '$subnet4'"
    exit 1
fi

srv_dir="${ovpn_dir}/servers/${srv_name}"
srv_crt="${srv_dir}/server.crt"
srv_key="${srv_dir}/server.key"

if [ "$force" = 'true' ]; then
    rm -rf "$srv_dir"
fi

if [ -f "$srv_crt" ] || [ -f "$srv_key" ]; then
    echo "server ${srv_name} already exists"
    exit 1
fi

cd "$easyrsa_dir" || exit 1

rm -f "./pki/issued/${cname}.crt"
rm -f "./pki/private/${cname}.key"
rm -f "./pki/reqs/${cname}.req"

export EASYRSA_CERT_EXPIRE=3650
./easyrsa build-server-full "$cname" nopass || exit 1

mkdir -p "$srv_dir"
cp -f "./pki/issued/${cname}.crt" "${srv_crt}"
cp -f "./pki/private/${cname}.key" "${srv_key}"

if [ -n "$subnet6" ]; then
    srv_proto6="${proto}6"
    ipv6_regex='s/^IF_IPV6.//g'
else
    srv_proto6="${proto}"
    ipv6_regex='/^IF_IPV6./D'
fi

if [ "$proto" = 'udp' ]; then
    cli_proto='udp'
    udp_regex='s/^IF_UDP.//g'
else
    cli_proto='tcp-client'
    udp_regex='/^IF_UDP./D'
fi

if [ -n "$addr" ]; then
    addr_regex="s|^(remote[[:space:]])[0-9a-f.:]+([[:space:]])|\\1${addr}\\2|g"
else
    addr_regex="s|KEEP_ADDR|KEEP_ADDR|"
fi

substitute()
{
    sed -r \
        -e "s|SERVER_NAME|${srv_name}|g" \
        -e "s|SERVER_CN|${cname}|g" \
        -e "s|SERVER_PORT|${port}|g" \
        -e "s|SERVER_PROTO6|${srv_proto6}|g" \
        -e "s|CLIENT_PROTO|${cli_proto}|g" \
        -e "s|SUBNET4_ADDR|${subnet4_addr}|g" \
        -e "s|SUBNET4_MASK|${subnet4_mask}|g" \
        -e "s|SUBNET6|${subnet6}|g" \
        -e "$ipv6_regex" \
        -e "$udp_regex" \
        -e "$addr_regex"
}

srv_conf="${ovpn_dir}/${srv_name}.conf"
cli_tmpl="${srv_dir}/template.ovpn"

cd "$ovpn_dir" || exit 1
substitute < "$tmpl_dir/server.tpl" > "$srv_conf" || exit 1
substitute < "$tmpl_dir/client.tpl" > "$cli_tmpl" || exit 1
chmod 600 "$srv_conf" "$cli_tmpl"

mkdir -p "${srv_dir}/clients" "${srv_dir}/configs"
touch "${srv_dir}/routes"

echo "OK"
