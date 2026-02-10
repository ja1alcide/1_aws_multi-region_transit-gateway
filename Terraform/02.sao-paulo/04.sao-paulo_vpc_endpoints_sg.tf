resource "aws_vpc_endpoint" "interface_endpoints_sp" {
  provider = aws.sao-paulo

  for_each = toset(var.endpoint_services)

  vpc_id            = module.vpc_sao_paulo.vpc_id
  service_name      = "com.amazonaws.${var.networks["sao-paulo"].region}.${each.value}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpce_sg_sp.id]

  subnet_ids = module.vpc_sao_paulo.private_subnet_id

  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-${each.value}-endpoint"
  }
}

# S3 gateway endpoint doesn't use SGs, it uses route tables
resource "aws_vpc_endpoint" "s3_gateway_sp" {
  provider = aws.sao-paulo

  vpc_id            = module.vpc_sao_paulo.vpc_id
  service_name      = "com.amazonaws.${var.networks["sao-paulo"].region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [module.vpc_sao_paulo.private_rt_id]

  tags = { Name = "${var.environment}-s3-gateway" }
}

# #################################################################
# VPC ENDPOINTS SECURITY GROUP CONFIG
# #################################################################

resource "aws_security_group" "vpce_sg_sp" {
  provider = aws.sao-paulo

  name        = "${var.environment}-vpce-sg"
  vpc_id      = module.vpc_sao_paulo.vpc_id
  description = "Security group for VPC Interface Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "vpce_in_sp" {
  provider = aws.sao-paulo

  security_group_id            = aws_security_group.vpce_sg_sp.id
  referenced_security_group_id = module.compute_sao_paulo.security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
