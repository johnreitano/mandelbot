resource "null_resource" "build_linux_executable" {
  provisioner "local-exec" {
    command = "cd .. && docker build  -f deploy/Dockerfile  --platform=linux/amd64 -o deploy/upload ."
  }

  triggers = {
    code_changed = join(",", [for f in setunion(fileset("..", "**/*.go"), fileset("..", "go.*"), fileset("..", "deploy/Dockerfile")) : filesha256("../${f}")])
  }
}

module "validator" {
  depends_on = [null_resource.build_linux_executable]

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
  num_instances             = var.num_validator_instances
  build_linux_executable_id = "${filesha256("upload/mandelbotd")}-${null_resource.build_linux_executable.id}"
}

# module "seed" {
#   source                          = "./modules/seed"
#   env                             = var.env
#   project                         = var.project
#   ssh_private_key_path            = var.ssh_private_key_path
#   ssh_public_key_path             = var.ssh_public_key_path
#   vpc_id                          = aws_vpc.vpc.id
#   igw_id                          = aws_internet_gateway.igw.id
#   subnet_cidr                     = var.seed_subnet_cidr
#   validator_ips                   = module.validator.ips
#   validator_genesis_file_contents = module.validator.genesis_file_contents
#   ami                             = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
#   # ami         = data.aws_ami.latest-ubuntu.id
#   num_instances = var.num_seed_instances
# }

# module "explorer" {
#   source               = "./modules/explorer"
#   env                  = var.env
#   project              = var.project
#   ssh_private_key_path = var.ssh_private_key_path
#   ssh_public_key_path  = var.ssh_public_key_path
#   vpc_id               = aws_vpc.vpc.id
#   igw_id               = aws_internet_gateway.igw.id
#   fe_subnet_cidr       = var.explorer_fe_subnet_cidr
#   be_0_subnet_cidr     = var.explorer_be_0_subnet_cidr
#   be_1_subnet_cidr     = var.explorer_be_1_subnet_cidr
#   ami                  = "ami-0ee8244746ec5d6d4" # Get deatils on this ami in https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#AMICatalog:
#   # ami         = data.aws_ami.latest-ubuntu.id
#   seed_ips                        = module.seed.ips
#   validator_genesis_file_contents = module.validator.genesis_file_contents
#   create_explorer                 = var.create_explorer
# }

