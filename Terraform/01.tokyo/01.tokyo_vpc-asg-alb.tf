# ##########################################################################
# TOKYO VPC - Main/Hub VPC
# ##########################################################################
module "main_vpc" {
  source = "../modules/vpc_networking"

  environment = var.environment
  owner       = var.owner

  tags     = var.networks["tokyo"].tags
  vpc_name = var.networks["tokyo"].vpc_name
  vpc_cidr = var.networks["tokyo"].vpc_cidr

  dns_support  = var.networks["tokyo"].dns_support
  dns_hostname = var.networks["tokyo"].dns_hostname

  public_subnets_config   = var.networks["tokyo"].public_subnets_config
  private_subnets_config  = var.networks["tokyo"].private_subnets_config
  isolated_subnets_config = var.networks["tokyo"].isolated_subnets_config


  enable_igw         = var.networks["tokyo"].enable_igw
  enable_nat_gateway = var.networks["tokyo"].enable_nat_gateway
}


# ##########################################################################
# TOKYO ASG COMPUTE (Hub)
# ##########################################################################
module "compute_tokyo" {
  source = "../modules/asg_launch_template"

  environment = var.environment
  owner       = var.owner
  tags        = var.tags

  vpc_id     = module.main_vpc.vpc_id
  subnet_ids = module.main_vpc.private_subnet_id

  target_group_arns = [module.alb_tokyo.target_group_arn]

  instance_name        = var.asg_config["tokyo"].instance_name
  instance_type        = var.asg_config["tokyo"].instance_type
  ami_id               = var.asg_config["tokyo"].ami_id
  key_name             = var.asg_config["tokyo"].key_name
  user_script          = var.asg_config["tokyo"].user_script
  public_ip_address    = try(var.asg_config["tokyo"].public_ip_address, false)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile["tokyo"].id

  min_size         = var.asg_config["tokyo"].min_size
  max_size         = var.asg_config["tokyo"].max_size
  desired_capacity = var.asg_config["tokyo"].desired_capacity

  create_sg      = try(var.asg_config["tokyo"].create_sg, true)
  sg_name        = var.asg_config["tokyo"].sg_name
  sg_description = var.asg_config["tokyo"].sg_description
  ingress_rules  = var.asg_config["tokyo"].ingress_rules
  added_ingress_rules = { # only allowing ingress traffic from the alb
    "alb_traffic" = {
      source_security_group_id = module.alb_tokyo.security_group_id
      from_port                = 80
      to_port                  = 80
      ip_protocol              = "tcp"
      description              = "Allow traffic from the Tokyo ALB"
    }
  }
}

##########################################################################
# Tokyo - ALB
##########################################################################
module "alb_tokyo" {
  source = "../modules/alb"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags

  vpc_id     = module.main_vpc.vpc_id
  subnet_ids = module.main_vpc.public_subnet_id

  # --- ALB Identification ---

  alb_name           = var.alb_config["tokyo"].alb_name
  internal           = var.alb_config["tokyo"].internal
  load_balancer_type = var.alb_config["tokyo"].load_balancer_type

  alb_ingress_rules   = var.alb_config["tokyo"].alb_ingress_rules
  alb_egress_rules    = var.alb_config["tokyo"].alb_egress_rules
  health_check_config = var.alb_config["tokyo"].health_check_config

  # --- Listeners & Logs ---
  http_port             = var.alb_config["tokyo"].http_port
  https_port            = var.alb_config["tokyo"].https_port
  certificate_arn       = aws_acm_certificate_validation.chewbacca_acm_validation01.certificate_arn
  enable_access_logs    = var.alb_config["tokyo"].enable_access_logs
  create_https_listener = var.alb_config["tokyo"].create_https_listener
  log_bucket_id         = aws_s3_bucket.audit_vault.id
  log_prefix            = var.alb_config["tokyo"].log_prefix

  listener_secret        = random_password.origin_header_value01.result
  http_header_name       = var.http_header_name
  enable_secure_listener = var.enable_secure_listener
}
