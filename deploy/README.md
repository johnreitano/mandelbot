# Deploying a testnet

## Step 1: Install dependencies

```
brew install jq terraform awscli
```

## Step 2: Generate name servers

From the project root dir:

```
terraform -chdir=deploy apply -var="dns_zone_name=mysubdomain.mydomain.com" -var="tls_certificate_email=myemail@example.com"
```

This command will output a list of name servers. At the host for the subdomain (eg, `mysubdomain`), add one NS record for each name server in the output. Wait for the NS records to be deployed (this can take anywhere from 15 minutes to 8 hours).

## Step 3: Deploy your chain

From the project root dir:

```
terraform -chdir=deploy apply -var="dns_zone_name=mysubdomain.mydomain.com" -var="tls_certificate_email=myemail@example.com" -var="num_validator_instances=3" -var="num_seed_instances=1" -var="create_explorer=true"
```

#### Step 4: Behold your testnet

Wait 2-3 minutes, the visit your new api:

```
open https://validator-0-api.mysubdomain.mydomain.com
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
