# ##########################################################################
# Sao-Paulo Terraform State lookup
# ##########################################################################

data "terraform_remote_state" "sao_paulo" {
  backend = "local"

  config = {
    path = "../02.sao-paulo/terraform.tfstate"
  }
}

data "aws_caller_identity" "jae_self02" {}

data "aws_elb_service_account" "main" {
  region = var.networks["tokyo"].region
}

# Instead of creating a zone, we look up the existing one by ID
data "aws_route53_zone" "selected" {
  zone_id = var.route53_hosted_zone_id
}

##############################################################
# Lab 2B-Honors - Origin Driven Caching (Managed Policies)
##############################################################

# Explanation: Chewbacca uses AWS-managed policies—battle-tested configs so students learn the real names.
data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers01" {
  name = "UseOriginCacheControlHeaders"
}

# Explanation: Same idea, but includes query strings in the cache key when your API truly varies by them.
data "aws_cloudfront_cache_policy" "chewbacca_use_origin_cache_headers_qs01" {
  name = "UseOriginCacheControlHeaders-QueryStrings"
}

# Explanation: Origin request policies let us forward needed stuff without polluting the cache key.
# (Origin request policies are separate from cache policies.) :contentReference[oaicite:6]{index=6}
data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer01" {
  name = "Managed-AllViewer"
}

data "aws_cloudfront_origin_request_policy" "chewbacca_orp_all_viewer_except_host01" {
  name = "Managed-AllViewerExceptHostHeader"
}

# The "No Cache" Policy
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}
