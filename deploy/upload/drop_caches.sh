#!/usr/bin/env bash

set -x
set -e

## run as cron, thus no $PATH, thus need to define all absolute paths
cpu=$(/usr/bin/printf %.0f $(/bin/ps -o pcpu= -C kswapd0))

[[ -n $cpu ]] && \
    (($cpu >= 90)) && \
    echo 3 >/proc/sys/vm/drop_caches && \
    echo "$$ $0: cache dropped (kswapd0 %CPU=$cpu)" 1>>/tmp/drop_caches.log && \
    exit 1
