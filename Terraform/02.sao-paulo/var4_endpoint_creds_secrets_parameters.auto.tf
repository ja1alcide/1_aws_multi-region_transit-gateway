# ##############################################################################
# ENDPOINT SERVICES +
# ##############################################################################

variable "endpoint_services" {
  description = "List of AWS services to create Interface Endpoints for"
  type        = list(string)
  default     = []
}

# ##############################################################################
# CREDENTIALS AND SECRETS
# ##############################################################################

variable "secret_name" {
  type = string
}

variable "secret_description" {
  type = string
}

variable "secret_tag" {
  type = map(any)
}

variable "db_username" {
  type    = string
  default = null
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "db_port" {
  description = "The port the MySQL database listens on"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "The name of the initial database to create"
  type        = string
  default     = null
}

variable "engine" {
  description = "The engine of the initial database to create"
  type        = string
  default     = null
}

# ========================================================================
# SSM PARAMETERS CONFIG
# ========================================================================
variable "parameters" {
  description = "Values needed for parameter creation"
  type = map(object({
    value       = string
    type        = string
    description = string
  }))
  default = {}
}

variable "db_config_path" {
  description = "The path in SSM Parameter Store where DB config is stored"
  type        = string
  default     = "/lab/db/"
}