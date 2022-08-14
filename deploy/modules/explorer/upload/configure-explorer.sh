#!/usr/bin/env bash

set -x
set -e

NODE_INDEX=$1

curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh
sudo bash /tmp/nodesource_setup.sh

curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn

if [[ ! -d "explorer" ]]; then
    git clone https://github.com/johnreitano/ping-pub-explorer.git explorer
fi
cd explorer
NEW_CHAIN_LOWER='new''chain'
NEW_CHAIN_UPPER='NEW''CHAIN'
NEW_CHAIN_TITLE='New''chain'
git checkout ${NEW_CHAIN_LOWER}-deployment
git pull
git grep -l $NEW_CHAIN_LOWER | xargs sed -i -e 's/'$NEW_CHAIN_LOWER'/mandelbot/g'
git grep -l $NEW_CHAIN_UPPER | xargs sed -i -e 's/'$NEW_CHAIN_UPPER'/NEWCHAIN/g'
git grep -l $NEW_CHAIN_TITLE | xargs sed -i -e 's/'$NEW_CHAIN_TITLE'/Newchain/g'
git mv public/logos/${NEW_CHAIN_LOWER}.png public/logos/mandelbot.png
git mv public/logos/${NEW_CHAIN_LOWER}stake.png public/logos/mandelbotstake.png
git mv src/chains/mainnet/${NEW_CHAIN_LOWER}.json src/chains/mainnet/mandelbot.json
git mv src/chains/testnet/${NEW_CHAIN_LOWER}.json src/chains/testnet/mandelbot.json
yarn

cat >/tmp/explorer.service <<-EOF
[Unit]
Description=blockchain explorer
Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=sudo -u ubuntu /home/ubuntu/upload/start-explorer.sh
ExecStop=sudo killall node
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target

EOF
sudo cp /tmp/explorer.service /etc/systemd/system/explorer.service
sudo chmod 664 /etc/systemd/system/explorer.service
sudo systemctl daemon-reload

# line="* * * * * /home/ubuntu/upload/drop_caches.sh"
# (
#     sudo crontab -l
#     echo "$line"
#     echo
# ) | sudo crontab -u root -

sudo sysctl vm.swappiness=0
sudo setcap cap_net_bind_service=ep /usr/bin/node
