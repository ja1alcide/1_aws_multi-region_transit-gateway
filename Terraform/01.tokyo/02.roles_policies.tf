# N.B. IAM is gloabl service, 
# so they can be created in the main accessed from other regions

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ec2_lab_role" {
  for_each = var.networks

  name = "${var.environment}-${each.key}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Policy to connect via SSM Session Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
  for_each = var.networks

  role       = aws_iam_role.ec2_lab_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  for_each = var.networks

  role = aws_iam_role.ec2_lab_role[each.key].name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "db_access_policy" {
  for_each = var.networks

  name        = "${var.environment}-${each.key}-db-app-access-policy"
  description = "Scoped access to specific parameters, secrets, and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSpecificSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.networks[each.key].region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"
      },
      {
        Sid      = "ReadSpecificParams"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${var.networks[each.key].region}:${data.aws_caller_identity.current.account_id}:parameter${var.db_config_path}*"
      },
      {
        Sid    = "WriteLogsAndMetrics"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData"
        ]
        Resource = "arn:aws:logs:${var.networks[each.key].region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/lab-rds-app:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_db_attach" {
  for_each = var.networks

  role       = aws_iam_role.ec2_lab_role[each.key].name
  policy_arn = aws_iam_policy.db_access_policy[each.key].arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  for_each = var.networks

  name = "${var.environment}-${each.key}-instance-profile"
  role = aws_iam_role.ec2_lab_role[each.key].name
}
