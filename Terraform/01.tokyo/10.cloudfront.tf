# Random password to be used by CF, Route 53 and ALBs
resource "random_password" "origin_header_value01" {
  length  = 32
  special = false
}


# CloudFront is the only public doorway
resource "aws_cloudfront_distribution" "tokyo_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "GlobalSmartOrigin"
    domain_name = "origin.${var.domain_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = var.http_header_name
      value = random_password.origin_header_value01.result
    }
  }

  # Default cache adjustment--------------------------------------------------------------------------------------
  # Default behavior is conservative
  default_cache_behavior {
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.chewbacca_orp_all_viewer01.id
  }

  #---------------------------------------------------------------------------------------------------------------
  # Static behavior is the speed lane
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.tokyo_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.tokyo_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.tokyo_rsp_static01.id
  }

  #---------------------------------------------------------------------------------------------------------------
  # Public feed is cacheable—but only if the origin explicitly says so.
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.chewbacca_use_origin_cache_headers01.id

    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.chewbacca_orp_all_viewer_except_host01.id
  }

  #---------------------------------------------------------------------------------------------------------------
  # Explanation: Everything else under /api is dangerous by default—Chewbacca disables caching until proven safe.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.chewbacca_use_origin_cache_headers_qs01.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.chewbacca_orp_all_viewer01.id
  }

  web_acl_id = aws_wafv2_web_acl.tokyo_waf01[0].arn

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.chewbacca_cf_validation01.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  # ---------------------------------------------------------
  # EDGE EVIDENCE LOGGING CONFIGURATION
  # ---------------------------------------------------------
  logging_config {
    include_cookies = false

    bucket = "${aws_s3_bucket.audit_vault.id}.s3.amazonaws.com"

    prefix = "Chwebacca-logs/"
  }
}


# ---------------------------------------------------------
# Caching policies
# ---------------------------------------------------------

resource "aws_cloudfront_cache_policy" "tokyo_cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400    
  max_ttl     = 31536000 
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config { cookie_behavior = "none" }

    query_strings_config { query_string_behavior = "none" }

    headers_config { header_behavior = "none" }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_origin_request_policy" "tokyo_orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }
}

resource "aws_cloudfront_response_headers_policy" "tokyo_rsp_static01" {
  name    = "${var.project_name}-rsp-static01"
  comment = "Add explicit Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}

