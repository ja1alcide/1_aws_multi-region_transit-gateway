# =============================================================
# SAO PAULO TGW CONFIG
# =============================================================

# Explanation: Liberdade is São Paulo’s Japanese town—local doctors, local compute, remote data.
resource "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider    = aws.sao-paulo
  description = "liberdade-tgw01 (Sao Paulo spoke)"
  tags        = { Name = "liberdade-tgw01" }
}

# Explanation: Liberdade opens a corridor request to Shinjuku—compute may travel, data may not.
resource "aws_ec2_transit_gateway_peering_attachment" "liberdade_to_shinjuku_peer01" {
  transit_gateway_id      = aws_ec2_transit_gateway.liberdade_tgw01.id
  peer_region             = "ap-northeast-1"
  peer_transit_gateway_id = data.terraform_remote_state.tokyo.outputs.tgw_id # created in Tokyo module/state
  tags                    = { Name = "shinjuku-to-liberdade-peer01" }
}


# Explanation: Liberdade attaches to its VPC—compute can now reach Tokyo legally, through the controlled corridor.
resource "aws_ec2_transit_gateway_vpc_attachment" "liberdade_attach_sp_vpc01" {
  provider           = aws.sao-paulo
  transit_gateway_id = aws_ec2_transit_gateway.liberdade_tgw01.id
  vpc_id             = module.vpc_sao_paulo.vpc_id
  subnet_ids         = module.vpc_sao_paulo.private_subnet_id

  tags = {
    Name = "liberdade-attach-sp-vpc01"
  }
}
