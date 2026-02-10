# Random password to be used by CF, Route 53 and ALBs
resource "random_password" "origin_header_value01" {
  length  = 32
  special = false
}


# Explanation: CloudFront is the only public doorway — Chewbacca stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "chewbacca_cf01" {
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

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = var.http_header_name
      value = random_password.origin_header_value01.result
    }
  }

  # Default cache adjustment--------------------------------------------------------------------------------------
  # Explanation: Default behavior is conservative—Chewbacca assumes dynamic until proven static.
  default_cache_behavior {
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.chewbacca_orp_all_viewer01.id
  }

  #---------------------------------------------------------------------------------------------------------------
  # Explanation: Static behavior is the speed lane—Chewbacca caches it hard for performance.
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.chewbacca_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.chewbacca_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.chewbacca_rsp_static01.id
  }

  #---------------------------------------------------------------------------------------------------------------
  # Explanation: Public feed is cacheable—but only if the origin explicitly says so. Chewbacca demands consent.
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "GlobalSmartOrigin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Honor Cache-Control from origin (and default to not caching without it). :contentReference[oaicite:8]{index=8}
    cache_policy_id = data.aws_cloudfront_cache_policy.chewbacca_use_origin_cache_headers01.id

    # Forward what origin needs. Keep it tight: don't forward everything unless required. :contentReference[oaicite:9]{index=9}
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

    # cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.chewbacca_use_origin_cache_headers_qs01.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.chewbacca_orp_all_viewer01.id
  }

  #This does the WAF association 
  web_acl_id = aws_wafv2_web_acl.chewbacca_waf01[0].arn

  # TODO: students set aliases for chewbacca-growl.com and app.chewbacca-growl.com
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # Having the viewer use the certificate validation will force the distribution resource to depend on the
  # cert validation to be completed before creating the the distribution
  # you coudl also use the 'depends on' function in terraform is you want to used the ACM Cert ARN.
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

    # CloudFront requires the .s3.amazonaws.com suffix
    bucket = "${aws_s3_bucket.audit_vault.id}.s3.amazonaws.com"

    # The mandatory requirement for the Malgus scripts
    prefix = "Chwebacca-logs/"
  }
}

#################################################
# Cache policy for static content (aggressive)
##############################################################

# Static files are the easy win—Chewbacca caches them like hyperfuel for speed.
resource "aws_cloudfront_cache_policy" "chewbacca_cache_static01" {
  name        = "${var.project_name}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    # Static should not vary on cookies—Chewbacca refuses to cache 10,000 versions of a PNG.
    cookies_config { cookie_behavior = "none" }

    # Static should not vary on query strings (unless you do versioning); students can change later.
    query_strings_config { query_string_behavior = "none" }

    # Keep headers out of cache key to maximize hit ratio.
    headers_config { header_behavior = "none" }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

##################################################################
# Origin request policy for static (minimal)
##############################################################

# Static origins need almost nothing—Chewbacca forwards minimal values for maximum cache sanity.
resource "aws_cloudfront_origin_request_policy" "chewbacca_orp_static01" {
  name    = "${var.project_name}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config { cookie_behavior = "none" }
  query_strings_config { query_string_behavior = "none" }
  headers_config { header_behavior = "none" }
}

##############################################################
# Response headers policy (optional but nice)
##############################################################

# Make caching intent explicit—Chewbacca stamps Cache-Control so humans and CDNs agree.
resource "aws_cloudfront_response_headers_policy" "chewbacca_rsp_static01" {
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

