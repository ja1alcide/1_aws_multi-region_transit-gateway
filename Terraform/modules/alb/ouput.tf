output "alb_dns_name" {
  description = "The public DNS name of the load balancer."
  value       = aws_lb.jae_alb.dns_name
}

output "alb_zone_id" {
  description = "The hosted zone ID of the load balancer (needed for Route53 Alias records)."
  value       = aws_lb.jae_alb.zone_id
}

output "alb_arn" {
  description = "The ARN of the load balancer."
  value       = aws_lb.jae_alb.arn
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the load balancer."
  value       = aws_lb.jae_alb.arn_suffix
}

output "security_group_id" {
  description = "The ID of the ALB security group. Pass this to the ASG module's 'added_ingress_rules'."
  value       = aws_security_group.jae_alb_sg.id
}

output "target_group_arn" {
  description = "The ARN of the Target Group. The ASG module needs this to register instances automatically."
  value       = aws_lb_target_group.jae_tg.arn
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener."
  value       = aws_lb_listener.jae_http_listener[*].arn
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener."
  value       = aws_lb_listener.jae_https_listener[*].arn
}