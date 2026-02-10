# GLOBAL VARIABLES

variable "environment" {
  description = "Environment for all resources."
  type        = string
  default     = "saopaulo-prod-3"
}

variable "owner" {
  description = "Owner for the created resources."
  type        = string
  default     = "Jae"
}

variable "project_name" {
  type = string
}

variable "networks" {
  description = "Map of all regional network configurations (Tokyo & Brazil)"
  type = map(object({

    region       = string
    vpc_name     = string
    vpc_cidr     = string
    dns_support  = bool
    dns_hostname = bool
    enable_igw   = bool

    enable_nat_gateway = bool

    tags = map(string)

    public_subnets_config = map(object({
      az_index  = number
      newbits   = number
      netnum    = number
      is_public = bool
    }))

    private_subnets_config = map(object({
      az_index     = number
      newbits      = number
      netnum       = number
      needs_nat_gw = bool
    }))

    isolated_subnets_config = map(object({
      az_index    = number
      newbits     = number
      netnum      = number
      isolated_on = bool
    }))
  }))
}

variable "tags" {
  description = "Tag values for global netowkr resources."
  type        = map(string)
  default     = {}
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}