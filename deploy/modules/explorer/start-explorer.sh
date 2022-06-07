#!/usr/bin/env bash
set -x
set -e

MONIKER="explorer"

cd ~/mandelbot
# nohup ignite chain serve --verbose >mandelbot.out 2>&1 </dev/null &
# nohup build/mandelbotd start >mandelbot.out 2>&1 </dev/null &
echo "About to start explorer node ${MONIKER} with id $(build/mandelbotd tendermint show-node-id)"
build/mandelbotd start
