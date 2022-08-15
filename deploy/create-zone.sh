#!/usr/bin/env bash
# set -x
set -e

SCRIPT_DIR=$(dirname $(readlink -f $0))
cd ${SCRIPT_DIR}/..
DNS_ZONE_NAME=$1
TLS_CERTIFICATE_EMAIL=$2
if [[ "$DNS_ZONE_NAME" = "" || "$TLS_CERTIFICATE_EMAIL" = "" ]]; then
    echo "Usage: ./create-zone.sh <full-dns-zone-name> <tls-certificate-contact-email>"
fi

cat >${SCRIPT_DIR}/dns.tfvars <<EOF
dns_zone_name = "$DNS_ZONE_NAME"
tls_certificate_email = "$TLS_CERTIFICATE_EMAIL"
EOF

terraform -chdir=deploy apply -auto-approve -var="num_validator_instances=0" -var="num_seed_instances=0" -var="create_explorer=false" -var="domain_prefix=testnet2-" -var-file="dns.tfvars"
