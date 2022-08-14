output "ips" {
  value = [for eip in aws_eip.validator : eip.public_ip]
}

output "genesis_file_available" {
  value = length(null_resource.generate_genesis_file) > 0
}
