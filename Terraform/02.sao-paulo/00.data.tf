# ##########################################################################
# Tokyo Terraform State lookup
# ##########################################################################

data "terraform_remote_state" "tokyo" {
  backend = "local"

  config = {
    path = "../01.tokyo/terraform.tfstate"
  }
}

# ##########################################################################

data "aws_elb_service_account" "sao-paulo" {
  #   region = var.networks["sao-paulo"].region
}

data "aws_caller_identity" "current" {}

data "aws_caller_identity" "jae_self02" {}

# Instead of creating a zone, we look up the existing one by ID
data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}