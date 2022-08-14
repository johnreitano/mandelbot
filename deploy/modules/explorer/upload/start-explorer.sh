#!/usr/bin/env bash
set -x
set -e

echo "About to start ping-pub block explorer server via yarn..."
cd ~/explorer
yarn serve
