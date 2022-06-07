#!/usr/bin/env bash

set -x
set -e

echo "***in configure-explorer.sh, args: $@"

# sleep until instance is ready
until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
    sleep 1
done

MONIKER="explorer"

THIS_IP=$1

SEED_IPS_STR=$2
SEED_IPS=(${SEED_IPS_STR//,/ })
SEED_P2P_KEYS=(9038832904699724f0b62188e088a86acb629fad de77ff9811178b9b14507dae3cde3ffa0df68130 192fd886732afb466690f1e098ddd62cfe7a63e4)

P2P_EXTERNAL_ADDRESS="tcp://${THIS_IP}:26656"

P2P_SEEDS=""
N=${#SEED_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    P2P_SEEDS="${P2P_SEEDS}${SEED_P2P_KEYS[$i]}@${SEED_IPS[$i]}:26656,"
done

rm -rf ~/.mandelbot
echo "***about to init"
build/mandelbotd init $MONIKER --chain-id mandelbot-test-1

cat >/tmp/mandelbot.service <<-EOF
[Unit]
Description=start mandelbot blockchain client running as a seed node
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/mandelbot/deploy/modules/explorer/start-explorer.sh ${NODE_INDEX}
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
echo "***about to run load service"
sudo cp /tmp/mandelbot.service /etc/systemd/system/mandelbot.service
sudo chmod 664 /etc/systemd/system/mandelbot.service
sudo systemctl daemon-reload

dasel put string -f ~/.mandelbot/config/config.toml -p toml ".p2p.external_address" "${P2P_EXTERNAL_ADDRESS}"
dasel put string -f ~/.mandelbot/config/config.toml -p toml ".p2p.seeds" "${P2P_SEEDS}"
dasel put bool -f ~/.mandelbot/config/app.toml -p toml ".api.enable" true

echo "***about to update"
if [[ -z "$(which docker)" ]]; then
    echo "***about to install docker"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
fi
if [[ -z "$(which psql)" ]]; then
    echo "***about to install psql"
    sudo apt install -y postgresql-client
fi

sudo docker rm -f postgresql 2>/dev/null
sudo docker run --name postgresql -e POSTGRES_USER=admin -e POSTGRES_PASSWORD=adminpassword -p 5432:5432 -v /pgdata:/var/lib/postgresql/data -d postgres
until psql -h $PG_HOST -U $PG_USER -d $PG_DATABASE -c "select 1" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
    echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
    sleep 1
done

sleep 5

echo "***about to clone repo"
cd ~
git clone https://github.com/forbole/bdjuno.git
cd bdjuno
git checkout chains/cosmos/testnet
make install
export PATH=$(go env GOPATH)/bin:$PATH

RETRIES=15
export PGPASSWORD=adminpassword
until psql -h 127.0.0.1 -U admin -p 5432 -c "select 1" >/dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
    echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
    sleep 1
done

psql -h 127.0.0.1 -U admin -p 5432 <<-EOF
CREATE DATABASE bdjuno;
CREATE USER bdjuno WITH ENCRYPTED PASSWORD 'bdjunopassword';
GRANT ALL PRIVILEGES ON DATABASE bdjuno TO bdjuno;
EOF

for f in ./database/schema/*.sql; do
    PGPASSWORD=bdjunopassword psql -h 127.0.0.1 -U bdjuno -p 5432 -d bdjuno -f ${f}
done

# NOTE: genesis file already copied to ~/.bdjuno/genesis.json
bdjuno init
dasel put string -f ~/.bdjuno/config.yaml -p yaml ".chain.bech32_prefix" "mandelbot"
dasel put string -f ~/.bdjuno/config.yaml -p yaml ".database.name" "bdjuno"
dasel put string -f ~/.bdjuno/config.yaml -p yaml ".database.user" "bdjuno"
dasel put string -f ~/.bdjuno/config.yaml -p yaml ".database.password" "bdjunopassword"

sudo docker rm -f hasura 2>/dev/null
sudo docker run --name hasura -e HASURA_GRAPHQL_UNAUTHORIZED_ROLE="anonymous" -e ACTION_BASE_URL="http://localhost:3000" -e HASURA_GRAPHQL_METADATA_DATABASE_URL="postgres://bdjuno:bdjunopassword@host.docker.internal:5432/bdjuno" -e PG_DATABASE_URL="postgres://bdjuno:bdjunopassword@host.docker.internal:5432/bdjuno" -e HASURA_GRAPHQL_ENABLE_CONSOLE="true" -e HASURA_GRAPHQL_DEV_MODE="true" -e HASURA_GRAPHQL_ENABLED_LOG_TYPES="startup, http-log, webhook-log, websocket-log, query-log" -e HASURA_GRAPHQL_ADMIN_SECRET="myadminsecretkey" -p 8080:8080 --add-host host.docker.internal:host-gateway -d hasura/graphql-engine

curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash

cd ~/bdjuno/hasura
hasura metadata apply --endpoint http://localhost:8080 --admin-secret myadminsecretkey

GOPATH=$(go env GOPATH)
sudo tee /etc/systemd/system/bdjuno.service >/dev/null <<EOF
[Unit]
Description=BDJuno parser
After=network-online.target

[Service]
User=$USER
ExecStart=$GOPATH/bin/bdjuno start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target

EOF

sudo chmod 664 /etc/systemd/system/bdjuno.service
sudo systemctl daemon-reload
