# Terraform password generated only for lab
# Only one is needed, password generated in Tokyo will be used in all regions
resource "random_password" "password" {
  length           = 30
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
#---------------------------------------------

resource "aws_secretsmanager_secret" "imported_secret" {
  description             = var.secret_description
  name                    = var.secret_name
  recovery_window_in_days = 0

  tags = var.secret_tag

  tags_all = var.secret_tag
}

resource "aws_secretsmanager_secret_version" "imported_version" {
  secret_id = aws_secretsmanager_secret.imported_secret.id
  version_stages = [
    "AWSCURRENT",
  ]

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.password.result
  })
}

resource "aws_ssm_parameter" "paramters" {
  for_each = var.parameters

  name        = each.key
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = var.secret_tag
}

resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/lab/db/endpoint"
  description = "Dynamic RDS Endpoint for MySQL Lab"
  type        = "String"
  value       = aws_db_instance.mysql_db.address

  tags = var.secret_tag
}