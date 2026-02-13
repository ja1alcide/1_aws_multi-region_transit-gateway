# ##########################################################################
# Sao-Paulo Terraform State lookup
# ##########################################################################

data "terraform_remote_state" "sao_paulo" {
  backend = "local"

  config = {
    path = "../02.sao-paulo/terraform.tfstate"
  }
}

# ##########################################################################
# Other Data lookups
# ##########################################################################

data "aws_caller_identity" "jae_self02" {}

data "aws_elb_service_account" "main" {
  region = var.networks["tokyo"].region
}

data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}

##############################################################
# Origin Driven Caching (Managed Policies)
##############################################################

data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers01" {
  name = "UseOriginCacheControlHeaders"
}

data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers_qs01" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}


data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer01" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer_except_host01" {
  name = "Managed-AllViewerExceptHostHeader"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}
