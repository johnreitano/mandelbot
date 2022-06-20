#!/usr/bin/env bash
set -x
set -e

NODE_INDEX=$1

if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi
echo MONIKER=$MONIKER

# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
nohup upload/mandelbotd start >mandelbot.out 2>&1 </dev/null &
sleep 2
echo "Started validator node ${MONIKER} with NODE_INDEX ${NODE_INDEX} and id $(upload/mandelbotd tendermint show-node-id)"
