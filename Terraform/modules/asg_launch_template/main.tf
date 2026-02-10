####################################################################################################
#Launch Template Config
####################################################################################################
resource "aws_launch_template" "main" {
  name_prefix = "${var.instance_name}-lt-"

  image_id      = var.ami_id != null ? var.ami_id : data.aws_ami.ami[0].id
  instance_type = var.instance_type
  key_name      = var.key_name

  # --- NETWORK CONFIGURATION ---
  network_interfaces {
    associate_public_ip_address = var.public_ip_address

    security_groups = concat(
      aws_security_group.main[*].id,
      var.additional_security_group_ids,
    )

    delete_on_termination = true
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  user_data = var.user_script != null ? filebase64("${path.root}/${var.user_script}") : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      local.common_tags,
      {
        Name = "${var.instance_name}-asg-node"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      local.common_tags,
      {
        Name = "${var.instance_name}-volume"
      }
    )
  }

  # Ensures Terraform manages the versions correctly
  update_default_version = true

  lifecycle {
    create_before_destroy = true # Essential for Zero-Downtime updates
  }
}

data "aws_ami" "ami" {
  # Acts as an on/off switch, where If false, count is 0 and no resource is created
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["amazon", "self"]

  dynamic "filter" {
    for_each = var.ami_filters
    content {
      name   = filter.key
      values = filter.value
    }
  }
}

####################################################################################################
# Security Group Config
####################################################################################################
resource "aws_security_group" "main" {
  # Acts as an on/off switch
  count = var.create_sg ? 1 : 0

  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${var.sg_name}-sg"
    }
  )

  # Prevents "Security Group In Use" errors during updates
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_ipv4" {
  for_each = var.create_sg ? var.ingress_rules : {}

  security_group_id = aws_security_group.main[0].id

  from_port   = each.value.from_port
  to_port     = each.value.to_port
  ip_protocol = each.value.ip_protocol
  cidr_ipv4   = each.value.cidr_ipv4
  description = each.value.description

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${each.key}-sg"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "allow_ipv4" {
  for_each = var.create_sg ? var.egress_rules : {}

  security_group_id = aws_security_group.main[0].id

  # Logic for "All Ports" (-1)
  from_port   = each.value.ip_protocol == "-1" ? null : each.value.from_port
  to_port     = each.value.ip_protocol == "-1" ? null : each.value.to_port
  ip_protocol = each.value.ip_protocol
  cidr_ipv4   = each.value.cidr_ipv4
  description = each.value.description

  tags = merge(
    var.tags,
    local.common_tags,
    {
      Name = "${each.key}-sg"
    }
  )
}

# Additonal, possible, Security Group Rule
resource "aws_security_group_rule" "ingress_from_sources" {
  for_each = var.create_sg ? var.added_ingress_rules : {}

  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.ip_protocol
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = aws_security_group.main[0].id
  description              = each.value.description
}

####################################################################################################
# Auto-Scaling Group Config
####################################################################################################

resource "aws_autoscaling_group" "main" {
  name                = "${var.instance_name}-asg"
  vpc_zone_identifier = var.subnet_ids # The list of private subnets

  # ASG Capacity Config
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Health Checks
  # "ELB" means health checks will be based on the ELB
  # "EC2" means health checks will be based on the EC2
  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = 300 # Give the app 5 mins to start up

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  # Load Balancer Integration
  # If you pass Target Group ARNs, the ASG automatically registers instances
  target_group_arns = var.target_group_arns

  # Instance Refresh (The "Zero Downtime" Magic)
  # This automatically rolls out updates if the the User Data or AMI chnages
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"] # Refresh if tags change (or just rely on LT version change)
  }

  # ASG tags propagate to instances via the 'tag' block, but
  # Launch Template tags are preferred (found in the LT block).
  # use this dynamic block just to tag the ASG.
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true # Redundant if using LT tags, but safe to keep
    }
  }

  # Essential for preventing destruction overlap
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity] # Let the auto-scaler manage this after creation
  }
}

####################################################################################################
# Key Pair Management Config
####################################################################################################
resource "aws_key_pair" "instance_key_pair" {
  count = var.key_needed ? 1 : 0

  key_name   = var.key_name
  public_key = tls_private_key.rsa[0].public_key_openssh # Point this to the public from the tls_private.rsaresource
}

resource "tls_private_key" "rsa" {
  count = var.key_needed ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "foo" {
  count = var.key_needed ? 1 : 0

  content         = tls_private_key.rsa[0].private_key_pem
  filename        = "${path.root}/${var.key_name}.pem"
  file_permission = "0400"
}