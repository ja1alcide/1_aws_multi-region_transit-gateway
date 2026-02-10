variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

# --- ALB Identification ---
variable "alb_name" {
  description = "Specific name for this ALB (e.g., 'app-alb')"
  type        = string
}

variable "internal" {
  description = "Boolean: Is this an internal load balancer?"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "The type of load balancer to create"
  type        = string
  default     = "application"
}

# --- Listener Settings ---
variable "http_port" {
  description = "Port for the HTTP listener and Security Group ingress"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Port for the HTTPS listener (if enabled)"
  type        = number
  default     = 443
}

variable "create_https_listener" {
  description = "Toggle to create https listener."
  type        = bool
  default     = true
}

# --- Security Group Settings ---

variable "alb_ingress_rules" {
  description = "Map of ingress rules for the ALB."
  type = map(object({
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
    description = optional(string, "ALB Inbound Rule")
  }))
  default = {
    "http" = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP from world"
    },
    "https" = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS from world"
    }
  }
}

variable "alb_egress_rules" {
  description = "Map of egress rules for the ALB."
  type = map(object({
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
    description = optional(string, "ALB Outbound Rule")
  }))
  default = {
    "all_out" = {
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all outbound traffic"
    }
  }
}

# --- Health Check Settings ---
variable "health_check_config" {
  description = "Configuration for Target Group health checks"
  type = object({
    path                = optional(string)
    protocol            = optional(string)
    matcher             = optional(string)
    interval            = optional(number)
    timeout             = optional(number)
    healthy_threshold   = optional(number)
    unhealthy_threshold = optional(number)
  })
  default = {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299" # Accepts 200 OK and 201 Created
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# --- Access Logs ---
variable "enable_access_logs" {
  type    = bool
  default = false
}

variable "log_bucket_id" {
  description = "S3 bucket ID for logs. Required if enable_access_logs is true."
  type        = string
  default     = null
}

variable "log_prefix" {
  type    = string
  default = "alb-logs"
}

# --- Metadata ---
variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

# --- Optional Certificates ---
variable "certificate_arn" {
  type    = string
  default = null
}

# --- Optional Listener Password & Header, secret will trigger new http creation ---
variable "enable_secure_listener" { #this is the toggle to trigger the new listener rule creation
  description = "Toggle to enable the secret-header secure listener"
  type        = bool
  default     = false # default off
}

variable "listener_secret" {
  description = "Shared secret for; If empty, ALB is open to the world."
  type        = string
  default     = ""
}

variable "http_header_name" {
  description = "Shared secret for; If empty, ALB is open to the world."
  type        = string
  default     = ""
}