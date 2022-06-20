output "ips" {
  value = [for eip in aws_eip.validator : eip.public_ip]
}

# output "genesis_file_contents" {
#   value = local.genesis_file_content
# }
