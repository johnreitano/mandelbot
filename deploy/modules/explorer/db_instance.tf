# resource "aws_db_parameter_group" "explorer" {
#   name   = "explorer"
#   family = "postgres14"

#   parameter {
#     name  = "log_connections"
#     value = "1"
#   }
# }

# resource "random_string" "random" {
#   length           = 16
#   special          = true
#   override_special = "$"
# }

# resource "aws_db_instance" "explorer" {
#   identifier             = "explorer"
#   instance_class         = "db.t3.micro"
#   allocated_storage      = 5
#   engine                 = "postgres"
#   engine_version         = "14.2"
#   username               = "explorer"
#   password               = random_string.random.result
#   db_subnet_group_name   = aws_db_subnet_group.explorer_be_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.explorer_be.id]
#   parameter_group_name   = aws_db_parameter_group.explorer.name
#   publicly_accessible    = true
#   skip_final_snapshot    = true
# }
