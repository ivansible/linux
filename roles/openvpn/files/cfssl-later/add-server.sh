#!/bin/bash

KEYSIZE=2048
EXPIRY="43800h"
CNAME="OpenVPN"

SDIR="$1"
CDIR="$1/clients"
[ -z "$SDIR" ] && echo "usage: $0 server" && exit 1

test -r /etc/apt/sources.list.d/duggan-ubuntu-jo-$(lsb_release -sc).list || \
  add-apt-repository -u -y ppa:duggan/jo
apt-get install -qqy jq jo curl ssl-cert

CA_CFG_JSON=$(jo signing=$(jo profiles=$(jo server=$(jo expiry=$EXPIRY usages=$(jo -a digital_signature key_encipherment server_auth)) client=$(jo expiry=$EXPIRY usages=$(jo -a signing client_auth)))) | tr _ ' ')

CACERT_JSON=$(jo cn="$CNAME CA" key[algo]=rsa key[size]=$KEYSIZE names=[$(jo C=US O=$CNAME)])
SERVER_JSON=$(jo cn="$CNAME Server" key[algo]=rsa key[size]=$KEYSIZE names=[$(jo C=US O=$CNAME)])

#set -x

test -d $SDIR && echo "server $SDIR alredy exists" && exit 1

mkdir -p $SDIR $SDIR/clients 2>/dev/null

test -r /usr/local/bin/cfssl || \
  curl -sLo /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
test -r /usr/local/bin/cfssljson || \
  curl -sLo /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod 755 /usr/local/bin/cfssl /usr/local/bin/cfssljson

cfssl genkey --initca <(echo $CACERT_JSON) | cfssljson -bare $SDIR/ca

cfssl gencert -ca $SDIR/ca.pem -ca-key $SDIR/ca-key.pem \
              -config=<(echo $CA_CFG_JSON) -profile="server" \
              -hostname="server" \
              <(echo $SERVER_JSON) | cfssljson -bare $SDIR/server

openvpn --genkey --secret $SDIR/ta.key

test ! -r $SDIR/dh.pem && \
  echo "please wait..." && \
  time openssl dhparam -out $SDIR/dh.pem $KEYSIZE 2>/dev/null && echo OK

chmod 600 $SDIR/*.pem $SDIR/*.key $SDIR/*.csr

