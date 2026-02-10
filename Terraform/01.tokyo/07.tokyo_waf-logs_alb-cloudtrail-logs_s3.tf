############################################
# THE AUDIT VAULT (S3)
# Central storage for all evidence
############################################
resource "aws_s3_bucket" "audit_vault" {
  bucket = "class-lab3-${data.aws_caller_identity.current.account_id}"

  force_destroy = true

  tags = {
    Name        = "Audit-Evidence-Vault"
    Compliance  = "APPI-Japan"
    Description = "Storage for CloudTrail - WAF and CloudFront Logs"
  }
}

# PROOF OF IMMUTABILITY: Versioning enabled
resource "aws_s3_bucket_versioning" "audit_vault_ver" {
  bucket = aws_s3_bucket.audit_vault.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "audit_vault_pab" {
  bucket = aws_s3_bucket.audit_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################################
# VAULT ACCESS POLICY
# Bucket Policy to Allow ALB, CloudFront, and CloudTrail to write here
############################################
resource "aws_s3_bucket_policy" "audit_vault_policy" {
  bucket = aws_s3_bucket.audit_vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Allow Tokyo ALB Logs
      {
        Sid       = "AllowALBWrite"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_vault.arn}/alb-logs/tokyo/*"
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_vault.arn,
          "${aws_s3_bucket.audit_vault.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      # 2. Allow CloudTrail (Change Management Proof)
      {
        Sid       = "AllowCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_vault.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.audit_vault.arn
      },
      # 3. Allow CloudFront (Edge Security)
      {
        Sid       = "AllowCloudFrontWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_vault.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

############################################
# CLOUDTRAIL - Satisfies "Who made any chnages" audit requirement
############################################
resource "aws_cloudtrail" "audit_trail" {
  name           = "compliance-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_vault.id

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true # Integrity validation

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  depends_on = [aws_s3_bucket_policy.audit_vault_policy]
}

############################################
# WAFv2 (The Shield)
############################################
resource "aws_wafv2_web_acl" "chewbacca_waf01" {
  provider = aws.us_e_1 # WAF for CloudFront MUST be in us-east-1

  count = var.enable_waf ? 1 : 0
  name  = "${var.project_name}-waf01"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf01"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-waf-common"
      sampled_requests_enabled   = true
    }
  }
}

############################################
# WAF LOGGING (Evidence Collection)
############################################
resource "aws_cloudwatch_log_group" "chewbacca_waf_log_group01" {
  provider          = aws.us_e_1
  count             = var.waf_log_destination == "cloudwatch" ? 1 : 0
  name              = "aws-waf-logs-${var.project_name}-webacl01"
  retention_in_days = var.waf_log_retention_days
}

# attaching WAF logs to CloudFront
resource "aws_wafv2_web_acl_logging_configuration" "chewbacca_waf_logging01" {
  provider                = aws.us_e_1
  count                   = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.chewbacca_waf01[0].arn
  log_destination_configs = [aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].arn]

  depends_on = [aws_wafv2_web_acl.chewbacca_waf01]
}

resource "aws_cloudwatch_log_resource_policy" "waf_logging_policy" {
  provider    = aws.us_e_1
  policy_name = "AWSWAF-LOGS-Policy"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "delivery.logs.amazonaws.com" }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].arn}:*"
    }]
  })
}

############################################
# WAF LOGGING (Evidence Collection)
############################################

# 1. Ownership Controls needed for WAF log info
# Tell S3 we prefer ACLs for this specific bucket
resource "aws_s3_bucket_ownership_controls" "audit_vault_ownership" {
  bucket = aws_s3_bucket.audit_vault.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# 2. Enable the ACL
resource "aws_s3_bucket_acl" "audit_vault_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.audit_vault_ownership]

  bucket = aws_s3_bucket.audit_vault.id
  acl    = "private"
}