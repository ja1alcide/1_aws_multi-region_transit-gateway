resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = toset(var.endpoint_services)

  vpc_id            = module.main_vpc.vpc_id
  service_name      = "com.amazonaws.${var.networks["tokyo"].region}.${each.value}"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.vpce_sg.id]

  subnet_ids = module.main_vpc.private_subnet_id

  private_dns_enabled = true

  tags = {
    Name = "${var.environment}-${each.value}-endpoint"
  }
}

# S3 gateway endpoint doesn't use SGs, it uses route tables
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = module.main_vpc.vpc_id
  service_name      = "com.amazonaws.${var.networks["tokyo"].region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [module.main_vpc.private_rt_id]

  tags = { Name = "${var.environment}-s3-gateway" }
}

# ##################################################################
# VPC ENDPOINTS SECURITY GROUP CONFIG
# ##################################################################

resource "aws_security_group" "vpce_sg" {
  name        = "${var.environment}-vpce-sg"
  vpc_id      = module.main_vpc.vpc_id
  description = "Security group for VPC Interface Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "vpce_in" {
  security_group_id            = aws_security_group.vpce_sg.id
  referenced_security_group_id = module.compute_tokyo.security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
