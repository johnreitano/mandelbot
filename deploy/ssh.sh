#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
NODE_TYPE=$1
NODE_INDEX=$2

IP=$(${SCRIPT_DIR}/show-ip.sh $NODE_TYPE $NODE_INDEX)

shift
shift
ssh ubuntu@${IP} $@
