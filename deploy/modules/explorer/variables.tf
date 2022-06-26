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

variable "subnet_cidr" {
  description = "CIDR block for explorer subnet"
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

variable "validator_ips" {
  description = "the ip addresses of the validator nodes"
}

variable "genesis_file_available" {
  description = "true if the genesis file is available"
  type        = bool
}
