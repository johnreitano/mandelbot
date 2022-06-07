#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
NODE_TYPE=$1
NODE_INDEX=$2

X=2

if [[ "${NODE_TYPE}" = "explorer" ]]; then
    JQ_QUERY=".${NODE_TYPE}_ip.value"
else
    JQ_QUERY=".${NODE_TYPE}_ips.value[${NODE_INDEX}]"
fi

terraform -chdir=$SCRIPT_DIR output --json | jq -r "${JQ_QUERY}"
