#!/bin/bash

KEYSIZE=2048
EXPIRY="43800h"
CNAME="OpenVPN"

SDIR="$1"
CDIR="$1/clients"
NAME="$2"
[ -z "$SDIR" -o -z "$NAME" ] && echo "usage: $0 server client" && exit 1
[ ! -d "$SDIR" ] && echo "please run add-server.sh $1" && exit 1

CA_CFG_JSON=$(jo signing=$(jo profiles=$(jo server=$(jo expiry=$EXPIRY usages=$(jo -a digital_signature key_encipherment server_auth)) client=$(jo expiry=$EXPIRY usages=$(jo -a signing client_auth)))) | tr _ ' ')

CLIENT_JSON=$(jo cn="$NAME" key[algo]=rsa key[size]=$KEYSIZE names=[$(jo C=US O=$CNAME)])

#set -x

cfssl gencert -ca $SDIR/ca.pem -ca-key $SDIR/ca-key.pem \
              -config=<(echo $CA_CFG_JSON) -profile="client" \
              -hostname="$NAME" \
              <(echo $CLIENT_JSON) | cfssljson -bare $CDIR/$NAME

chmod 600 $CDIR/*.pem $CDIR/*.csr

