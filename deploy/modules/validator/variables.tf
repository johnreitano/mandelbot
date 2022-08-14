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

variable "tls_certificate_email" {
  description = "email to send to letsencrypt for tls certificates"
}

variable "num_instances" {
  description = "the number of instances"
  type        = number
}

variable "ami" {
  description = "the ami to use for instances"
}

variable "dns_zone_id" {
  description = "id of route53 dns zone"
}

variable "domain_prefix" {
  description = "domain name prefix"
}

variable "dns_zone_name" {
  description = "fully qualified domain of route53 dns zone"
}
