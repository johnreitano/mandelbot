#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..

terraform -chdir=deploy apply -auto-approve -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var="domain_prefix=testnet2-" -var-file="dns.tfvars"
