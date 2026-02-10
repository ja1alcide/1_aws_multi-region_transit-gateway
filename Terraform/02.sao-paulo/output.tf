output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc_sao_paulo.vpc_id
}

output "vpc_cidr" {
  description = "CIDR for Sao Paulo VPC"
  value       = module.vpc_sao_paulo.vpc_cidr
}

output "tgw_id" {
  description = "ID of the created TGW in Sao Paulo"
  value       = aws_ec2_transit_gateway.liberdade_tgw01.id
}

output "tgw_peering_attachment_id" {
  description = "The Peering Attachment ID for Sao Paulo TGW"
  value       = aws_ec2_transit_gateway_peering_attachment.liberdade_to_shinjuku_peer01.id
}

output "sao-paulo_s3_bucket_name" {
  description = "Name for Sao-Paulo S3 bucket"
  value       = aws_s3_bucket.sp_local_vault[0].id
}

output "tgw_routetable_id" {
  description = "Route Table ID for Sao Paulo TGW"
  value       = aws_ec2_transit_gateway.liberdade_tgw01.association_default_route_table_id
}

############################################

