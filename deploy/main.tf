locals {
  compressed_source_path = "/tmp/mandelbot/code/mandelbot.tar.gz"
  source_dir             = dirname(local.compressed_source_path)
}

resource "null_resource" "prepare_source" {
  provisioner "local-exec" {
    command = <<-EOF
      if [[ ! -f "${local.compressed_source_path}" ]]; then
        rm -rf ${local.source_dir}
        mkdir -p ${local.source_dir}
        cd ..
        git ls-files | tar -czf ${local.compressed_source_path} -T -
      fi
    EOF
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

module "validator" {
  source               = "./modules/validator"
  env                  = var.env
  project              = var.project
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id
  subnet_cidr          = var.validator_subnet_cidr
  ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances          = var.num_validator_instances
  compressed_source_path = local.compressed_source_path
}

module "seed" {
  source                          = "./modules/seed"
  env                             = var.env
  project                         = var.project
  ssh_private_key_path            = var.ssh_private_key_path
  ssh_public_key_path             = var.ssh_public_key_path
  vpc_id                          = aws_vpc.vpc.id
  igw_id                          = aws_internet_gateway.igw.id
  subnet_cidr                     = var.seed_subnet_cidr
  validator_ips                   = module.validator.ips
  validator_genesis_file_contents = module.validator.genesis_file_contents
  ami                             = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  num_instances          = var.num_seed_instances
  compressed_source_path = local.compressed_source_path
}

module "explorer" {
  source               = "./modules/explorer"
  env                  = var.env
  project              = var.project
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  vpc_id               = aws_vpc.vpc.id
  igw_id               = aws_internet_gateway.igw.id
  fe_subnet_cidr       = var.explorer_fe_subnet_cidr
  be_0_subnet_cidr     = var.explorer_be_0_subnet_cidr
  be_1_subnet_cidr     = var.explorer_be_1_subnet_cidr
  ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
  # ami         = data.aws_ami.latest-ubuntu.id
  seed_ips                        = module.seed.ips
  validator_genesis_file_contents = module.validator.genesis_file_contents
  create_explorer                 = var.create_explorer
  compressed_source_path          = local.compressed_source_path
}

