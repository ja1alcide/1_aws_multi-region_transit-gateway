# --- ALB Security Group ---
resource "aws_security_group" "jae_alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Public ALB security group for ${var.alb_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.project_name}-alb-sg" })
}

resource "aws_security_group_rule" "alb_ingress" {
  for_each = var.alb_ingress_rules

  type              = "ingress"
  security_group_id = aws_security_group.jae_alb_sg.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.ip_protocol
  cidr_blocks = [each.value.cidr_ipv4]
  description = each.value.description
}

resource "aws_security_group_rule" "alb_egress" {
  for_each = var.alb_egress_rules

  type              = "egress"
  security_group_id = aws_security_group.jae_alb_sg.id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  protocol    = each.value.ip_protocol
  cidr_blocks = [each.value.cidr_ipv4]
  description = each.value.description
}

# --- Application Load Balancer ---
resource "aws_lb" "jae_alb" {
  name               = "${var.project_name}-${var.environment}-alb"
  load_balancer_type = var.load_balancer_type
  internal           = var.internal
  security_groups    = [aws_security_group.jae_alb_sg.id]
  subnets            = var.subnet_ids

  # Access Logs: Controlled by a dynamic block based on your boolean
  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.log_bucket_id
      prefix  = var.log_prefix
      enabled = true
    }
  }

  tags = merge(var.tags, { Name = "${var.project_name}-alb" })
}

# --- Target Group ---
resource "aws_lb_target_group" "jae_tg" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_config.path
    protocol            = var.health_check_config.protocol
    matcher             = var.health_check_config.matcher
    interval            = var.health_check_config.interval
    timeout             = var.health_check_config.timeout
    healthy_threshold   = var.health_check_config.healthy_threshold
    unhealthy_threshold = var.health_check_config.unhealthy_threshold
  }

  tags = merge(var.tags, { Name = "${var.project_name}-tg" })
}

# --- HTTP Listener (Optional) ---
# Not created if password exissts 
resource "aws_lb_listener" "jae_http_listener" {
  count = var.enable_secure_listener ? 0 : 1

  load_balancer_arn = aws_lb.jae_alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jae_tg.arn
  }
}

# --- HTTPS Listener (Conditional) ---
resource "aws_lb_listener" "jae_https_listener" {
  count = var.create_https_listener == true ? 1 : 0

  load_balancer_arn = aws_lb.jae_alb.arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# ------------------------------------------------------------------
# --- Optional "Secure" Listener (Secret Provided) ---
# Created ONLY if the password exists
resource "aws_lb_listener" "jae_http_listener_secure" {
  count = var.enable_secure_listener ? 1 : 0

  load_balancer_arn = aws_lb.jae_alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  # Secure Mode: Default is to BLOCK
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "403 Forbidden - Direct Access Not Allowed"
      status_code  = "403"
    }
  }
}

# Attaches only to the SECURE listener
resource "aws_lb_listener_rule" "allow_cloudfront_secret" {
  count = var.enable_secure_listener ? 1 : 0

  # Note the array index [0] because we are referencing a resource with 'count'
  listener_arn = aws_lb_listener.jae_http_listener_secure[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jae_tg.arn
  }

  condition {
    http_header {
      http_header_name = var.http_header_name
      values           = [var.listener_secret]
    }
  }
}