variable "sns_topic_name" {
  type    = string
  default = "lab-db-incidents"
}

variable "sns_topic_display_name" {
  type    = string
  default = "DB Incident Alert"
}

variable "sns_subscriptions" {
  description = "A map of subscriptions to create for the SNS topic"
  type = map(object({
    protocol = string
    endpoint = string
  }))
}

variable "db_alarms" {
  description = "A map of CloudWatch metric alarms to create"
  type = map(object({
    metric_name         = string
    namespace           = string
    statistic           = string
    comparison_operator = string
    threshold           = number
    period              = number
    evaluation_periods  = number
    description         = string
  }))
}
