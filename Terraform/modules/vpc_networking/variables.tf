
variable "environment" {
  description = "Environment for VPC and other resource."
  type        = string
  default     = "test"
}

variable "owner" {
  description = "Owner for the created resourcess"
  type        = string
  default     = "Jae"
}

##############################################
# Info for VPC and Subnet
variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block range for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_support" {
  description = "Boolean value for to enable DNS support, on VPC"
  type        = bool
  default     = true
}

variable "dns_hostname" {
  description = "Boolean value for to enable DNS hostname, on VPC"
  type        = bool
  default     = true
}

variable "public_subnets_config" {
  description = "Configuration details for subnets, each object is a sbunet; some values will be used with the cidrsubnet function."
  type = map(object({  # the name of the object will be the name of the subnet.
    az_index  = number # index number for desired AZ from list of available AZ's
    newbits   = number # number to add to VPC CIDR Mask to create subnet mask
    netnum    = number # Value to create a new subnet network address, a subnet of VPC CIDR Mask 
    is_public = bool
  }))

  default = {
    "1st_public_subnet" = {
      az_index  = 0
      newbits   = 8
      netnum    = 1
      is_public = false
    }
  }
}

# These subnets can become completely private/ isolated based on NAT GW existance. 
variable "private_subnets_config" {
  description = "Configuration details for subnets, each object is a sbunet; some values will be used with the cidrsubnet function."
  type = map(object({     # the name of the object will be the name of the subnet.
    az_index     = number # index number for desired AZ from list of available AZ's
    newbits      = number # number to add to VPC CIDR Mask to create subnet mask
    netnum       = number # Value to create a new subnet network address, a subnet of VPC CIDR Mask 
    needs_nat_gw = bool
  }))

  default = {
    "1st_private_subnet" = {
      az_index     = 0
      newbits      = 8
      netnum       = 11
      needs_nat_gw = false
    }
  }
}

# These subnets are completely isolated, no NAT GW.
variable "isolated_subnets_config" {
  description = "Configuration details for subnets, each object is a sbunet; some values will be used with the cidrsubnet function."
  type = map(object({    # the name of the object will be the name of the subnet.
    az_index    = number # index number for desired AZ from list of available AZ's
    newbits     = number # number to add to VPC CIDR Mask to create subnet mask
    netnum      = number # Value to create a new subnet network address, a subnet of VPC CIDR Mask 
    isolated_on = bool
  }))

  default = {
    "1st_isolated_subnet" = {
      az_index    = 0
      newbits     = 8
      netnum      = 100
      isolated_on = false
    }
  }
}


#############################################
# varibale to turn on or off igw

variable "enable_igw" {
  description = "This variable will determine if an IGW is created."
  type        = bool
  default     = true
}

#############################################
# tagging variables
variable "tags" {
  description = "Tag values for VPC ceated."
  type        = map(string)

  default = {}
}

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}
#############################################

# variables for EIP nd Nat, if any private_subnet_config has needs_nat_gw = true, this must be true
variable "enable_nat_gateway" {
  description = "This boolean will determine if NAT and EIP are created"
  type        = bool
  default     = false
}
#############################################
