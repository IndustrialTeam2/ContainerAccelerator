

# resource "aws_security_group" "secgrp-rds" {

#   name        = "secgrp-rds"
#   description = "Allow MySQL Port"
 
#   ingress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "RDS"
#   }
# }

# resource "random_string" "username" {
#   length           = 16
#   special          = false
#   override_special = "/@£$"
# }


# resource "random_string" "password" {
#   length           = 16
#   special          = false
#   override_special = "/@£$"
# }





# resource "aws_db_instance" "rds" {
 
#   engine               = "mysql"
#   engine_version       = "5.7"
#   instance_class       = "db.t2.micro"
#   allocated_storage    = 10
#   storage_type         = "gp2"
#   db_name              = "wordpress"
#   username             = random_string.username.result
#   password             = random_string.password.result
#   parameter_group_name = "default.mysql5.7"
#   publicly_accessible = true
#   skip_final_snapshot = true
#   vpc_security_group_ids = [aws_security_group.secgrp-rds.id]
# }


# output "rds_address" {
#   value = aws_db_instance.rds.address
# }

# output "rds_endpoint" {
#   value = aws_db_instance.rds.endpoint
# }

# output "rds_username" {
#   value = aws_db_instance.rds.username
# }

# output "rds_password" {
#   value = nonsensitive(aws_db_instance.rds.password)
# }

