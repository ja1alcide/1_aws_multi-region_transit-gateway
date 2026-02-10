output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.main_vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR for Tokyo VPC"
  value       = module.main_vpc.vpc_cidr
}

output "tgw_id" {
  description = "ID of the created TGW in Tokyo"
  value       = aws_ec2_transit_gateway.shinjuku_tgw01.id
}

output "rds_endpoint" {
  description = "rds endpoint for DB in tokyo"
  value       = aws_db_instance.mysql_db.address
}

output "s3_bucket_name" {
  description = "Name for Tokyo S3 bucket"
  value       = aws_s3_bucket.audit_vault.id
}

output "cloudfront_dns_name" {
  description = "Domain name for Cloudfront distribution"
  value       = aws_cloudfront_distribution.chewbacca_cf01.domain_name
}

output "db_random_password" {
  description = "Random assword generated for RDS DB"
  value       = random_password.password.result
  sensitive   = true
}

output "db_endpoint" {
  description = "Ednpoint address for created Database"
  value       = aws_db_instance.mysql_db.address
}

output "random_header_password" {
  description = "Radnom Password for custom Coudfront header"
  value       = random_password.origin_header_value01.result
  sensitive   = true
}

output "validated_certificate_arn" {
  description = "Certificate ARN for certificate in use"
  value       = aws_acm_certificate_validation.chewbacca_acm_validation01.certificate_arn
}

############################################

