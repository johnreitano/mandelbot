#!/usr/bin/env bash

set -x
set -e

cd ~/mandelbot
THIS_NODE_ID=$(build/mandelbotd tendermint show-node-id)
for f in ~/.mandelbot/config/gentx/gentx-*.json; do
    base=$(basename ${f})
    if [[ "${base}" != "gentx-${THIS_NODE_ID}.json" ]]; then
        ADDRESS=$(cat ${f} | jq -r '.body.messages[0].delegator_address')
        AMOUNT=$(cat ${f} | jq -r '.body.messages[0].value.amount')
        DENOM=$(cat ${f} | jq -r '.body.messages[0].value.denom')
        echo build/mandelbotd add-genesis-account ${ADDRESS} ${AMOUNT}${DENOM} || :
    fi
done
build/mandelbotd collect-gentxs
