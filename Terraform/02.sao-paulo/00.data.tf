
data "terraform_remote_state" "tokyo" {
  backend = "local"

  config = {
    path = "../01.tokyo/terraform.tfstate"
  }
}

data "aws_elb_service_account" "sao-paulo" {
  #   region = var.networks["sao-paulo"].region
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}