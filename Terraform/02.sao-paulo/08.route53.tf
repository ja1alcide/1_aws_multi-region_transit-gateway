
# --- Route 53 Record: São Paulo Latency Target ---
resource "aws_route53_record" "origin_saopaulo" {
  zone_id = data.aws_route53_zone.selected.zone_id

  name = "origin.${var.domain_name}"
  type = "A"

  set_identifier = "SaoPaulo-Latency-Target"

  alias {
    name                   = module.alb_sao_paulo.alb_dns_name
    zone_id                = module.alb_sao_paulo.alb_zone_id
    evaluate_target_health = true
  }

  # Latency based routing = "Use this record if sa-east-1 is the fastest region"
  latency_routing_policy {
    region = "sa-east-1"
  }
}
