# -------------------------------------------------------------------------
# ALB Access Logs Vault
# -------------------------------------------------------------------------

resource "aws_s3_bucket" "sp_local_vault" {
  provider = aws.sao-paulo

  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-${var.networks["sao-paulo"].region}-alb-logs-${data.aws_caller_identity.current.account_id}-final"

  force_destroy = true

  tags = { Name = "${var.project_name}-alb-logs-bucket01" }
}

resource "aws_s3_bucket_public_access_block" "sao_paulo_alb_logs_pab02" {
  provider = aws.sao-paulo

  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.sp_local_vault[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -------------------------------------------------------------------------
# VAULT ACCESS POLICY
# -------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "sao_paulo_alb_logs_policy02" {
  provider = aws.sao-paulo

  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.sp_local_vault[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSPALBWrite"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.sao-paulo.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.sp_local_vault[0].arn}/alb-logs/sao-paulo/*"
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.sp_local_vault[0].arn,
          "${aws_s3_bucket.sp_local_vault[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}
