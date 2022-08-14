resource "aws_route53_zone" "default" {
  name = var.dns_zone_name
}

resource "null_resource" "build_linux_executable" {
  count = var.num_validator_instances > 0 || var.num_seed_instances > 0 ? 1 : 0

  provisioner "local-exec" {
    command = "cd .. && DOCKER_SCAN_SUGGEST=false docker build -f deploy/Dockerfile  --platform=linux/amd64 -o deploy/upload ."
  }

  triggers = {
    code_changed = join(",", [for f in setunion(fileset("..", "**/*.go"), fileset("..", "go.*"), fileset("..", "deploy/Dockerfile")) : filesha256("../${f}")])
  }
}

module "validator" {
  depends_on = [null_resource.build_linux_executable]

  source                = "./modules/validator"
  env                   = var.env
  project               = var.project
  ssh_private_key_path  = var.ssh_private_key_path
  ssh_public_key_path   = var.ssh_public_key_path
  tls_certificate_email = var.tls_certificate_email
  vpc_id                = aws_vpc.vpc.id
  igw_id                = aws_internet_gateway.igw.id
  subnet_cidr           = var.validator_subnet_cidr
  ami                   = "ami-0ee8244746ec5d6d4" # See https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog: - alternate: ami = data.aws_ami.latest-ubuntu.id
  dns_zone_id           = aws_route53_zone.default.zone_id
  dns_zone_name         = var.dns_zone_name
  domain_prefix         = var.domain_prefix
  num_instances         = var.num_validator_instances
}


module "seed" {
  source                 = "./modules/seed"
  env                    = var.env
  project                = var.project
  ssh_private_key_path   = var.ssh_private_key_path
  ssh_public_key_path    = var.ssh_public_key_path
  tls_certificate_email  = var.tls_certificate_email
  vpc_id                 = aws_vpc.vpc.id
  igw_id                 = aws_internet_gateway.igw.id
  subnet_cidr            = var.seed_subnet_cidr
  validator_ips          = module.validator.ips
  genesis_file_available = module.validator.genesis_file_available
  ami                    = "ami-0ee8244746ec5d6d4" # See https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog: - alternate: ami = data.aws_ami.latest-ubuntu.id
  dns_zone_id            = aws_route53_zone.default.zone_id
  dns_zone_name          = var.dns_zone_name
  domain_prefix          = var.domain_prefix
  num_instances          = var.num_seed_instances
}

module "explorer" {
  source                = "./modules/explorer"
  env                   = var.env
  project               = var.project
  ssh_private_key_path  = var.ssh_private_key_path
  ssh_public_key_path   = var.ssh_public_key_path
  tls_certificate_email = var.tls_certificate_email
  vpc_id                = aws_vpc.vpc.id
  igw_id                = aws_internet_gateway.igw.id
  subnet_cidr           = var.explorer_subnet_cidr
  ami                   = "ami-0ee8244746ec5d6d4" # See https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog: - alternate: ami = data.aws_ami.latest-ubuntu.id
  create_explorer       = var.create_explorer
  dns_zone_id           = aws_route53_zone.default.zone_id
  dns_zone_name         = var.dns_zone_name
  domain_prefix         = var.domain_prefix
}

