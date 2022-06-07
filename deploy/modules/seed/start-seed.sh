#!/usr/bin/env bash
set -x
set -e

NODE_INDEX=$1

if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="black"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="white"
else
    MONIKER="gray"
fi

cd ~/mandelbot
# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
# nohup build/mandelbotd start >mandelbot.out 2>&1 </dev/null &
echo "About to start seed node ${MONIKER} with NODE_INDEX ${NODE_INDEX} and id $(build/mandelbotd tendermint show-node-id)"
build/mandelbotd start
