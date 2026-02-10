resource "aws_db_subnet_group" "rds_private_group" {
  name        = "lab-rds-private-subnet-group"
  description = "RDS Subnet Group for lab using private subnets"

  subnet_ids = [for id in module.main_vpc.isolated_subnet_id : id]

  tags = merge(var.tags, { Name = "Lab DB Subnet Group" })
}

resource "aws_db_instance" "mysql_db" {

  identifier        = aws_ssm_parameter.paramters["/lab/db/name"].value
  allocated_storage = 20
  engine            = var.engine
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  username = var.db_username
  password = random_password.password.result

  port = aws_ssm_parameter.paramters["/lab/db/port"].value

  db_subnet_group_name   = aws_db_subnet_group.rds_private_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false

  skip_final_snapshot = true
  deletion_protection = false

  tags = merge(var.tags, { Name = "Tokyo DB Instance" })
}

# ------------------------------------------------------------------------
# DB Security Group Config
# ------------------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "rds-private-sg"
  description = "Isolated security group for RDS"
  vpc_id      = module.main_vpc.vpc_id

  tags = merge(local.common_tags, {
    Name = "rds-private-sg"
  })
}

# need to double check this, TF says it already exists
resource "aws_vpc_security_group_ingress_rule" "rds_ingress_from_ec2" {

  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = module.compute_tokyo.security_group_id

  from_port   = 3306
  to_port     = 3306
  ip_protocol = "tcp"
  description = "Inbound only from EC2 Web Tier"
}

resource "aws_vpc_security_group_egress_rule" "rds_egress_all" {
  security_group_id = aws_security_group.rds_sg.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}