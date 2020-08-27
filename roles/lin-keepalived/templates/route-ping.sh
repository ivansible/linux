#!/bin/bash
shift 1
fping -a -r1 "$@" |grep -Eq '[.:]'
