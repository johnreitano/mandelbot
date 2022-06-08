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

VALIDATOR_IPS_STR=$2
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${VALIDATOR_IPS[$NODE_INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    if [[ "${i}" != "${NODE_INDEX}" ]]; then
        P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
    fi
done

cd ~/mandelbot
rm -rf ~/.mandelbot
build/mandelbotd init $MONIKER --chain-id mandelbot-test-1
cp deploy/node_key_validator_${NODE_INDEX}.json ~/.mandelbot/config/node_key.json

cat >/tmp/mandelbot.service <<-EOF
[Unit]
Description=start mandelbot blockchain client running as a validator node
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/mandelbot/deploy/modules/validator/start-validator.sh ${NODE_INDEX}
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
sudo cp /tmp/mandelbot.service /etc/systemd/system/mandelbot.service
sudo chmod 664 /etc/systemd/system/mandelbot.service
sudo systemctl daemon-reload

dasel put string -f ~/.mandelbot/config/config.toml -p toml ".p2p.external_address" "${P2P_EXTERNAL_ADDRESS}"
dasel put string -f ~/.mandelbot/config/config.toml -p toml ".p2p.persistent_peers" "${P2P_PERSISTENT_PEERS}"
dasel put bool -f ~/.mandelbot/config/app.toml -p toml ".api.enable" true
