# Deploying a testnet

## Step 1: Install dependencies

```
brew install jq terraform awscli
```

## Step 2: Deploy

From the project root dir:

```
terraform -chdir=deploy apply
```

#### Step 3: Behold your testnet

See your api:

```
open `deploy/show-api.sh validator 0`
```

See your servers in AWS:

```
open https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:
```

See your ip addresses:

```
terraform -chdir=deploy output
# => seed_ips = [
#   "44.228.170.68",
# ]
# validator_ips = [
#   "35.165.126.194",
#   "52.43.111.204",
#   "54.200.98.222",
#]
```

Use some nifty commands in your scripts:

```
deploy/show-ip.sh seed 0
# => 44.228.170.68
deploy/show-ip.sh validator 0
# => 35.165.126.194
deploy/show-api.sh validator 0
# => http://35.165.126.194:1317
deploy/ssh.sh validator 0
# => ubuntu@ip-10-0-2-45:~$
deploy/ssh validator 0 date
# => Tue May 31 02:23:06 UTC 2022
```

## Destroying your testnet (to save money!)

From your project root dir:

```
terraform chdir=deploy destroy
```
