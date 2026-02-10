variable "asg_config" {
  description = "Ultimate Map of ASG configurations, allowing regional AMI lookups."
  type = map(object({
    instance_name = string
    instance_type = string
    ami_id        = optional(string)

    # The filters to find an AMI if ami_id, will not be used if ami_ids provided
    ami_filters = optional(map(list(string)), {
      name = ["al2023-ami-2023.*-kernel-*-x86_64"] # Default to Amazon Linux 2023
    })

    key_name             = string
    user_script          = optional(string)
    iam_instance_profile = optional(string)
    public_ip_address    = optional(bool, false)


    min_size         = number
    max_size         = number
    desired_capacity = number

    sg_name        = string
    sg_description = optional(string, "Managed by Terraform")
    create_sg      = optional(bool, true)

    ingress_rules = map(object({
      from_port                = number
      to_port                  = number
      ip_protocol              = string
      cidr_ipv4                = optional(string)
      source_security_group_id = optional(string)
      description              = optional(string)
    }))
  }))
}
variable "added_ingress_rules" {
  description = "Map to allow additonal ingress for security group IDs and/or the ports to open for them."
  type = map(object({
    source_security_group_id = optional(string)
    from_port                = number
    to_port                  = number
    ip_protocol              = string
    description              = optional(string, "Inbound from dynamic source")
  }))
  default = {}
}