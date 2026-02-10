# ##########################################################################
# Sao-paulo VPC - Spoke VPC
# ##########################################################################
module "vpc_sao_paulo" {
  source = "../modules/vpc_networking"

  providers = {
    aws = aws.sao-paulo
  }

  environment = var.environment
  owner       = var.owner

  tags     = var.networks["sao-paulo"].tags
  vpc_name = var.networks["sao-paulo"].vpc_name
  vpc_cidr = var.networks["sao-paulo"].vpc_cidr

  dns_support  = var.networks["sao-paulo"].dns_support
  dns_hostname = var.networks["sao-paulo"].dns_hostname

  public_subnets_config   = var.networks["sao-paulo"].public_subnets_config
  private_subnets_config  = var.networks["sao-paulo"].private_subnets_config
  isolated_subnets_config = var.networks["sao-paulo"].isolated_subnets_config


  enable_igw         = var.networks["sao-paulo"].enable_igw
  enable_nat_gateway = var.networks["sao-paulo"].enable_nat_gateway
}

# Additonal route from Liberdade (Sao-Paulo) to tokyo  
resource "aws_route" "liberdade_to_tokyo_route01" {
  provider               = aws.sao-paulo
  route_table_id         = module.vpc_sao_paulo.private_rt_id
  destination_cidr_block = data.terraform_remote_state.tokyo.outputs.vpc_cidr # Tokyo VPC CIDR (students supply)
  transit_gateway_id     = aws_ec2_transit_gateway.liberdade_tgw01.id
}


##########################################################################
# Sao-Paulo - ASG
##########################################################################
module "compute_sao_paulo" {
  source = "../modules/asg_launch_template"

  providers = {
    aws = aws.sao-paulo
  }

  # 1. Global Metadata
  environment = var.environment
  owner       = var.owner
  tags        = var.tags

  vpc_id     = module.vpc_sao_paulo.vpc_id
  subnet_ids = module.vpc_sao_paulo.private_subnet_id

  target_group_arns = [module.alb_sao_paulo.target_group_arn]

  instance_name        = var.asg_config["sao-paulo"].instance_name
  instance_type        = var.asg_config["sao-paulo"].instance_type
  ami_id               = var.asg_config["sao-paulo"].ami_id
  key_name             = var.asg_config["sao-paulo"].key_name
  user_script          = var.asg_config["sao-paulo"].user_script
  public_ip_address    = try(var.asg_config["sao-paulo"].public_ip_address, false)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile["sao-paulo"].id

  min_size         = var.asg_config["sao-paulo"].min_size
  max_size         = var.asg_config["sao-paulo"].max_size
  desired_capacity = var.asg_config["sao-paulo"].desired_capacity

  create_sg      = try(var.asg_config["sao-paulo"].create_sg, true)
  sg_name        = var.asg_config["sao-paulo"].sg_name
  sg_description = var.asg_config["sao-paulo"].sg_description
  ingress_rules  = var.asg_config["sao-paulo"].ingress_rules
  added_ingress_rules = {
    "alb_traffic" = {
      source_security_group_id = module.alb_sao_paulo.security_group_id
      from_port                = 80
      to_port                  = 80
      ip_protocol              = "tcp"
      description              = "Allow traffic from the Tokyo ALB"
    }
  }
}


##########################################################################
# Sai-Paulo - ALB
##########################################################################
module "alb_sao_paulo" {
  source = "../modules/alb"
  providers = {
    aws = aws.sao-paulo
  }

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags

  vpc_id     = module.vpc_sao_paulo.vpc_id
  subnet_ids = module.vpc_sao_paulo.public_subnet_id

  # --- ALB Identification ---

  alb_name           = var.alb_config["sao-paulo"].alb_name
  internal           = var.alb_config["sao-paulo"].internal
  load_balancer_type = var.alb_config["sao-paulo"].load_balancer_type

  alb_ingress_rules   = var.alb_config["sao-paulo"].alb_ingress_rules
  alb_egress_rules    = var.alb_config["sao-paulo"].alb_egress_rules
  health_check_config = var.alb_config["sao-paulo"].health_check_config

  # --- Listeners & Logs ---
  http_port             = var.alb_config["sao-paulo"].http_port
  https_port            = var.alb_config["sao-paulo"].https_port
  certificate_arn       = data.terraform_remote_state.tokyo.outputs.validated_certificate_arn
  enable_access_logs    = var.alb_config["sao-paulo"].enable_access_logs
  create_https_listener = var.alb_config["sao-paulo"].create_https_listener
  log_bucket_id         = aws_s3_bucket.sp_local_vault[0].id
  log_prefix            = var.alb_config["sao-paulo"].log_prefix

  listener_secret        = data.terraform_remote_state.tokyo.outputs.random_header_password
  http_header_name       = var.http_header_name
  enable_secure_listener = var.enable_secure_listener
}