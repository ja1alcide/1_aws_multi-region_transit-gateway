# =========================================================================
# COMMON INFO
# =========================================================================
variable "environment" {
  description = "Environment for resources (e.g., prod, dev, test)."
  type        = string
  default     = "test"
}

variable "owner" {
  description = "Owner of the created resources."
  type        = string
  default     = "Jae"
}

variable "tags" {
  description = "Map of custom tags to apply to all resources."
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

# =========================================================================
# AUTO SCALING GROUP CONFIG
# =========================================================================

variable "min_size" {
  description = "The minimum size of the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "The maximum size of the Auto Scaling Group."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group."
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in (VPC Zone Identifier)."
  type        = list(string)
  # No default - must be provided to ensure placement is correct
}

variable "target_group_arns" {
  description = "A list of aws_lb_target_group ARNs, for use with Application or Network Load Balancing."
  type        = list(string)
  default     = []
}

# =========================================================================
# LAUNCH TEMPLATE CONFIG
# =========================================================================

variable "instance_name" {
  description = "Name prefix for the Launch Template and ASG instances."
  type        = string
  default     = "app-node"
}

variable "instance_type" {
  description = "The type of instance to start."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Specific AMI ID to use. If null, the module will look up the latest AMI based on filters."
  type        = string
  default     = null
}

variable "ami_filters" {
  description = "Map of filters used to query for an AMI if ami_id is null."
  type        = map(list(string))
  default = {
    name = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
}

variable "key_name" {
  description = "The key name to use for the instance."
  type        = string
  default     = null
}

variable "key_needed" {
  description = "Boolean to trigger creation of a new TLS private key and Key Pair resource."
  type        = bool
  default     = true
}

variable "public_ip_address" {
  description = "Associate a public IP address with an instance in a VPC."
  type        = bool
  default     = false
}

variable "user_script" {
  description = "Path to the user data script file (relative to root)."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to associate with the instances."
  type        = string
  default     = null
}

# =========================================================================
# SECURITY GROUP CONFIG
# =========================================================================

variable "create_sg" {
  description = "Controls if a new Security Group is created."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The VPC ID where the Security Group will be created."
  type        = string
  default     = null
}

variable "sg_name" {
  description = "Name of the Security Group to create."
  type        = string
  default     = "app-sg"
}

variable "sg_description" {
  description = "Description of the Security Group."
  type        = string
  default     = "Managed by Terraform ASG Module"
}

variable "additional_security_group_ids" {
  description = "List of existing Security Group IDs to attach to the instances IN ADDITION to the one created by this module."
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "Map of ingress rules to create."
  type = map(object({
    from_port                = number
    to_port                  = number
    ip_protocol              = string
    cidr_ipv4                = optional(string)
    source_security_group_id = optional(string)
    description              = optional(string)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules to create."
  type = map(object({
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = optional(string)
    description = optional(string)
  }))
  default = {
    "all traffic" = {
      from_port   = 0
      to_port     = 0
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = null
    }
  }
}

# ADDITONAL SECURITY GROUPS CONFIG
# =========================================================================
variable "added_ingress_rules" {
  description = "Allows additonal ingress rule for security group."
  type = map(object({
    source_security_group_id = optional(string)
    from_port                = number
    to_port                  = number
    ip_protocol              = string
    description              = optional(string, "Inbound from dynamic source")
  }))
  default = {}
}