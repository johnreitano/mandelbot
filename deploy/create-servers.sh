#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..

NUM_VALIDATORS=$1
if [[ "$NUM_VALIDATORS" = "" ]]; then
    NUM_VALIDATORS=1
fi

terraform -chdir=deploy apply -auto-approve -var="num_validator_instances=$NUM_VALIDATORS" -var="num_seed_instances=1" -var="create_explorer=true" -var="domain_prefix=testnet2-" -var-file="dns.tfvars"
