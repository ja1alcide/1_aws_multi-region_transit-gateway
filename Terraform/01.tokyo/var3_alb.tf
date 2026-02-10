variable "alb_config" {
  description = "Map of configuration objects for ALBs per region"
  type = map(object({

    alb_name           = string
    internal           = optional(bool, false)
    load_balancer_type = optional(string, "application")

    http_port  = optional(number, 80)
    https_port = optional(number, 443)

    create_https_listener = optional(bool, true)

    certificate_arn = optional(string, null)

    alb_ingress_rules = optional(map(object({ #Setting commonly used varibales accros all regions
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_ipv4   = string
      description = optional(string)
      })),
      {
        "custom_http" = {
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          cidr_ipv4   = "0.0.0.0/0"
          description = "Standard HTTP"
        },
        "custom_https" = {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = "0.0.0.0/0"
          description = "Allow HTTPS from everywhere"
        }
      }
    )

    alb_egress_rules = optional(map(object({ #Setting commonly used varibales accros all regions
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_ipv4   = string
      description = optional(string)
      })),
      {
        "all_out" = {
          from_port   = 0
          to_port     = 0
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
          description = "Allow all outbound (Parent Configured)"
        }
      }
    )

    health_check_config = optional(object({       #Setting commonly used varibales accros all regions
      path                = optional(string, "/") # aim to update app to have '/health' path for proper health checks
      protocol            = optional(string, "HTTP")
      matcher             = optional(string, "200-299")
      interval            = optional(number, 15)
      timeout             = optional(number, 3)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 2)
    }), {})

    # --- Logging ---
    enable_access_logs = optional(bool, false)
    log_bucket_id      = optional(string, null)
    log_prefix         = optional(string, "alb-logs")
  }))
}



