variable "env" {
  description = "Deployment Environment"
}

variable "project" {
  description = "Project name"
}

variable "vpc_id" {
  description = "The vpc id for the project"
}

variable "igw_id" {
  description = "The id of the internet gatewy used by the project"
}

variable "fe_subnet_cidr" {
  description = "CIDR block for explorer fe subnet"
}

variable "be_0_subnet_cidr" {
  description = "CIDR block for explorer be_0 subnet"
}

variable "be_1_subnet_cidr" {
  description = "CIDR block for explorer be_1 subnet"
}

variable "ssh_private_key_path" {
  description = "path to private SSH key file"
  default     = "~/.ssh/id_rsa"
  type        = string
}

variable "ssh_public_key_path" {
  description = "path to public SSH key file"
  default     = "~/.ssh/id_rsa.pub"
  type        = string
}


variable "ami" {
  description = "the ami to use for instances"
}

variable "create_explorer" {
  description = "whether to include an explorere node"
}

variable "seed_ips" {
  description = "the ip addresses of the seed nodes"
}
variable "validator_genesis_file_contents" {
  description = "the contents of the genesis file from the first validator node"
}
