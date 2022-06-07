output "ip" {
  value = length(aws_eip.explorer) == 0 ? "" : aws_eip.explorer[0].public_ip
}

# output "initial_db_password" {
#   value = random_string.random.result
# }
