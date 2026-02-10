resource "aws_sns_topic" "db_alerts" {
  name         = var.sns_topic_name
  display_name = var.sns_topic_display_name

  tags = var.secret_tag
}

resource "aws_sns_topic_subscription" "dynamic_subs" {
  for_each = var.sns_subscriptions

  topic_arn = aws_sns_topic.db_alerts.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
}

resource "aws_cloudwatch_metric_alarm" "db_alarms" {
  for_each = var.db_alarms

  alarm_name          = each.key
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  treat_missing_data  = "notBreaching" # added so that no added errors is read as OK

  alarm_actions = [aws_sns_topic.db_alerts.arn]

  tags = var.networks["tokyo"].tags
}