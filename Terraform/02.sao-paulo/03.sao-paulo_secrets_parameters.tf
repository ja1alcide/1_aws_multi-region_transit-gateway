resource "aws_secretsmanager_secret" "imported_secret-sao-paulo" {
  provider = aws.sao-paulo

  description             = var.secret_description
  name                    = var.secret_name
  recovery_window_in_days = 0

  tags = var.secret_tag

  tags_all = var.secret_tag
}

resource "aws_secretsmanager_secret_version" "imported_version-sao-paulo" {
  provider = aws.sao-paulo


  secret_id = aws_secretsmanager_secret.imported_secret-sao-paulo.id
  version_stages = [
    "AWSCURRENT",
  ]

  secret_string = jsonencode({
    username = var.db_username
    password = data.terraform_remote_state.tokyo.outputs.db_random_password
  })
}

resource "aws_ssm_parameter" "paramters-sao-paulo" {
  provider = aws.sao-paulo

  for_each = var.parameters

  name        = each.key
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = var.secret_tag
}

resource "aws_ssm_parameter" "db_endpoint-sao-paulo" {
  provider = aws.sao-paulo

  name        = "/lab/db/endpoint"
  description = "Dynamic RDS Endpoint for MySQL Lab"
  type        = "String"
  value       = data.terraform_remote_state.tokyo.outputs.db_endpoint


  tags = var.secret_tag
}