############################################
# CloudWatch Dashboard for ALB: The Cockpit HUD
############################################

resource "aws_cloudwatch_dashboard" "saopaulo_dashboard02" {
  provider = aws.sao-paulo

  dashboard_name = "${var.project_name}-${var.networks["sao-paulo"].region}-dashboard01"

  # The dashboard_body is a JSON string. We use jsonencode to keep it clean.
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.alb_sao_paulo.alb_arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", module.alb_sao_paulo.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "saopaulo ALB: Requests vs 5XX Errors"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.alb_sao_paulo.alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "saopaulo ALB: Target Response Time (Latency)"
        }
      }
    ]
  })
}

# ############################################
# SNS Topic for ALB Alerts
# ############################################

resource "aws_sns_topic" "saopaulo_sns_topic02" {
  provider = aws.sao-paulo

  name = "${var.project_name}-alb-alerts"
}

resource "aws_cloudwatch_metric_alarm" "saopaulo_alb_5xx_alarm02" {
  provider = aws.sao-paulo


  alarm_name          = "${var.project_name}-${var.networks["sao-paulo"].region}-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count" # Best for monitoring App crashes

  dimensions = {
    LoadBalancer = module.alb_sao_paulo.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.saopaulo_sns_topic02.arn]
}