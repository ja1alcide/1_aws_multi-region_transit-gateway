variable "listener_secret" {
  description = "Shared secret for; If empty, ALB is open to the world."
  type        = string
  default     = ""
}

variable "enable_secure_listener" { #this is the toggle to trigger the new listener rule creation
  description = "Toggle to enable the secret-header secure listener"
  type        = bool
  default     = false # default off
}

variable "http_header_name" {
  description = "Shared secret for; If empty, ALB is open to the world."
  type        = string
  default     = "X-Chewbacca-Growl"
}
