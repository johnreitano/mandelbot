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
  description = "The cidr for the subnet"
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

variable "num_instances" {
  description = "the number of instances"
  type        = number
}

variable "ami" {
  description = "the ami to use for instances"
}

variable "validator_ips" {
  description = "the ip addresses of the validator nodes"
}

variable "validator_genesis_file_contents" {
  description = "the contents of the genesis file from the first validator node"
}

variable "compressed_source_path" {
  description = "the path to compressed source (.tar.gz file)"
}

