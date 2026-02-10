# =========================================================================
# AUTO SCALING GROUP
# =========================================================================

output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.id
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

# =========================================================================
# LAUNCH TEMPLATE
# =========================================================================

output "launch_template_id" {
  description = "The ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "The ARN of the Launch Template"
  value       = aws_launch_template.main.arn
}

output "launch_template_latest_version" {
  description = "The latest version of the Launch Template"
  value       = aws_launch_template.main.latest_version
}

# =========================================================================
# SECURITY GROUP 
# =========================================================================

output "security_group_id" {
  description = "ID of the Security Group created by the module"
  # We use [0] because the resource uses 'count', but if created, we want the single string ID, not a list.
  value = var.create_sg ? aws_security_group.main[0].id : null
}

output "security_group_arn" {
  description = "ARN of the Security Group created by the module"
  value       = var.create_sg ? aws_security_group.main[0].arn : null
}
