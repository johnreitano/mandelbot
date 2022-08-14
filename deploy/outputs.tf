output "validator_ips" {
  value = module.validator.ips
}

output "seed_ips" {
  value = module.seed.ips
}

output "explorer_ip" {
  value = module.explorer.ip
}

output "dns_name_servers" {
  value = aws_route53_zone.default.name_servers # for each of these records, add an NS record to zone's DNS manager
}

