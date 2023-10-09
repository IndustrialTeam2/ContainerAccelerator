# This creates a security group for the RDS instance
#
# Arguments
# - `name`: The name of the security group.
# - `description`: The description of the security group.
# - `vpc_id`: The ID of the VPC in which to create the security group.
# - `ingress`: A list of ingress rules to create for the security group.
#     * `from_port`: The start port (or ICMP type number if protocol is "icmp" or "icmpv6").
#     * `to_port`: The end port (or ICMP code if protocol is "icmp").
#     * `protocol`: The protocol. If you select a protocol of "-1" (semantically equivalent to "all", which is not a valid value here), you must specify a "from_port" and "to_port" equal to 0. If not icmp, tcp, udp, or "-1" use the [protocol number](https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml)
#     * `cidr_blocks`: List of CIDR blocks.
# - `egress`: A list of egress rules to create for the security group.
#     * `from_port`: The start port (or ICMP type number if protocol is "icmp" or "icmpv6").
#     * `to_port`: The end port (or ICMP code if protocol is "icmp").
#     * `protocol`: The protocol. If you select a protocol of "-1" (semantically equivalent to "all", which is not a valid value here), you must specify a "from_port" and "to_port" equal to 0. If not icmp, tcp, udp, or "-1" use the [protocol number](https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml)
#     * `cidr_blocks`: List of CIDR blocks.
# - `tags`: A map of tags to associate with the security group.
resource "aws_security_group" "secgrp-rds" {

  name        = "secgrp-rds"
  description = "Allow MySQL Port"
  vpc_id = module.vpc.vpc_id
 
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS"
  }
}

# This creates a random username for the RDS instance
#
# Arguments
# - `length`: The length of the string. Defaults to 8.
# - `special`: Whether to include special characters. Defaults to true.
# - `override_special`: A string of characters to always include in the generated string.
resource "random_string" "username" {
  length           = 16
  special          = false
  override_special = "/@£$"
}

# This creates a random password for the RDS instance
#
# Arguments
# - `length`: The length of the string. Defaults to 8.
# - `special`: Whether to include special characters. Defaults to true.
# - `override_special`: A string of characters to always include in the generated string.
resource "random_string" "password" {
  length           = 16
  special          = false
  override_special = "/@£$"
}

# This creates a subnet group for the RDS instance
#
# Arguments
# - `name`: The name of the DB subnet group. If omitted, Terraform will assign a random, unique name.
# - `description`: The description of the DB subnet group. Defaults to "Managed by Terraform".
# - `subnet_ids`: A list of VPC subnet IDs.
resource "aws_db_subnet_group" "rds" {
    name = "rds"
    subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
}

# This creates an RDS instance
#
# Arguments
# - `engine`: The database engine to use. For supported values, see the Engine parameter in the [Amazon RDS API Reference](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html).
# - `engine_version`: The engine version to use. For supported values, see the EngineVersion parameter in the [Amazon RDS API Reference](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html).
# - `instance_class`: The instance type of the RDS instance.
# - `allocated_storage`: The allocated storage in gigabytes.
# - `storage_type`: The type of storage. For supported values, see the StorageType parameter in the [Amazon RDS API Reference](https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html).
# - `db_name`: The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance.
# - `username`: Username for the master DB user.
# - `password`: Password for the master DB user. You can use [secrets](https://www.terraform.io/docs/providers/aws/r/db_instance.html#password) to prevent the password from being stored in plain text.
# - `parameter_group_name`: The name of the DB parameter group to associate with this instance.
# - `publicly_accessible`: Bool to control if instance is publicly accessible. Default is false.
# - `skip_final_snapshot`: Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from FinalSnapshotIdentifier. Default is false.
# - `vpc_security_group_ids`: List of VPC security groups to associate.
# - `db_subnet_group_name`: Name of DB subnet group.
resource "aws_db_instance" "rds" {
 
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  allocated_storage    = 10
  storage_type         = "gp2"
  db_name              = "wordpress"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = true
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.secgrp-rds.id]
  db_subnet_group_name = aws_db_subnet_group.rds.name
}


output "rds_address" {
  value = aws_db_instance.rds.address
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "rds_username" {
  value = aws_db_instance.rds.username
}

output "rds_password" {
  sensitive = true
  value = aws_db_instance.rds.password
}

