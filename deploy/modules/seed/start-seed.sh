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

# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
# nohup upload/mandelbotd start >mandelbot.out 2>&1 </dev/null &
echo "About to start seed node ${MONIKER} with NODE_INDEX ${NODE_INDEX} and id $(upload/mandelbotd tendermint show-node-id)"
upload/mandelbotd start
