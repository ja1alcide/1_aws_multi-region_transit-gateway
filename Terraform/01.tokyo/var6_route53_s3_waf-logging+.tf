
############################################
# Project General Variables
############################################

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

############################################
# Bonus B - Route 53, Connectivity & DNS Variables
############################################

variable "domain_name" {
  description = "Base domain you registered (e.g., yourdomain.com)."
  type        = string
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app)."
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method (DNS or EMAIL)."
  type        = string
  default     = "DNS"
}

variable "route53_hosted_zone_id" {
  description = "Hosted Zone ID for pre-existing Hosted Zone"
  default     = null
}

variable "manage_route53_in_terraform" {
  description = "Set to true to create a new Route53 zone, false to use an existing one."
  type        = bool
  default     = false
}

############################################
# Bonus B - Security & Monitoring Toggles
############################################

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Toggle ALB access logs to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for logs."
  type        = string
  default     = "alb-logs"
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period in seconds."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}

############################################
# WAF CONFIG
############################################

variable "waf_log_destination" {
  description = "The target for WAF logs. Set to 'cloudwatch' to enable the current resources."
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Number of days to keep logs in CloudWatch to manage costs"
  type        = number
  default     = 7
}
