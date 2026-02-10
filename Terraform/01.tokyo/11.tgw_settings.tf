# =============================================================
# TOKYO TGW CONFIG
# =============================================================

# Explanation: Shinjuku Station is the hub—Tokyo is the data authority.
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description = "shinjuku-tgw01 (Tokyo hub)"
  tags        = { Name = "shinjuku-tgw01" }
}

# Shinjuku connects to the Tokyo VPC—this is the gate to the medical records vault; 
# creates explicit ENI connection in VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = module.main_vpc.vpc_id
  subnet_ids         = module.main_vpc.isolated_subnet_id

  tags = {
    Name = "shinjuku-attach-tokyo-vpc01"
  }
}