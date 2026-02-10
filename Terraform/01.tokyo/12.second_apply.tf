# # ########################################################################################
# # THESE FILES SHOULD BE UNCOMMENTD ONLY FOR THE SECOND `terraform apply` IN THS DIRECTORY
# # To destroy infrastructure properly, make sure the file's code it commented out!
# # ########################################################################################

# # =============================================================
# #  Route to Sao-Paulo for Tokyo traffic
# # =============================================================

# #Additonal route from tokyo to Liberdade (Sao-Paulo)  
# resource "aws_route" "shinjuku_to_sp_route01" {

#   route_table_id         = module.main_vpc.private_rt_id
#   destination_cidr_block = data.terraform_remote_state.sao_paulo.outputs.vpc_cidr
#   transit_gateway_id     = aws_ec2_transit_gateway.shinjuku_tgw01.id
# }


# # =============================================================
# #  DB Security Group Config to allow Sao-Paulo access
# # =============================================================

# # to be placed in second_apply.tf file
# resource "aws_security_group_rule" "shinjuku_rds_ingress_from_liberdade01" {
#   type              = "ingress"
#   security_group_id = aws_security_group.rds_sg.id
#   from_port         = 3306
#   to_port           = 3306
#   protocol          = "tcp"

#   cidr_blocks = [data.terraform_remote_state.sao_paulo.outputs.vpc_cidr] # Sao Paulo VPC CIDR (students supply)
# }


# # =============================================================
# # TRANSIT GATEWAY PEERING ATTACHMENT & OUTPUT
# # =============================================================

# # Explanation: Shinjuku accepts the corridor from Liberdade—permissions are explicit, not assumed.
# resource "aws_ec2_transit_gateway_peering_attachment_accepter" "liberdade_accept_peer01" {
#   transit_gateway_attachment_id = data.terraform_remote_state.sao_paulo.outputs.tgw_peering_attachment_id
#   tags                          = { Name = "shinjuku-accept-peer01" }
# }


# # =============================================================
# # ROUTING INSIDE THE TRANSIT GATEWAYS
# # =============================================================

# # THE PAUSE BUTTON
# # Forces Terraform to wait 60s for the Peering to stabilize
# # before TGW Routes get created and attached
# resource "time_sleep" "wait_for_tgw_peering" {
#   create_duration = "60s"

#   depends_on = [
#     aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01
#   ]
# }

# # # Tell Tokyo TGW: "To reach São Paulo (10.191.0.0/16), go through the Peering Attachment"
# resource "aws_ec2_transit_gateway_route" "tokyo_tgw_to_sp" {
#   destination_cidr_block         = data.terraform_remote_state.sao_paulo.outputs.vpc_cidr
#   transit_gateway_attachment_id  = data.terraform_remote_state.sao_paulo.outputs.tgw_peering_attachment_id
#   transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.association_default_route_table_id

#   # DEPEND ON THE TIMER, NOT THE ATTACHMENT
#   depends_on = [time_sleep.wait_for_tgw_peering]
# }

# # # Tell São Paulo TGW: "To reach Tokyo (10.190.0.0/16), go through the Peering Attachment"
# resource "aws_ec2_transit_gateway_route" "sp_tgw_to_tokyo" {
#   provider = aws.sao-paulo

#   destination_cidr_block         = var.networks["tokyo"].vpc_cidr
#   transit_gateway_attachment_id  = data.terraform_remote_state.sao_paulo.outputs.tgw_peering_attachment_id
#   transit_gateway_route_table_id = data.terraform_remote_state.sao_paulo.outputs.tgw_routetable_id

#   # DEPEND ON THE TIMER
#   depends_on = [time_sleep.wait_for_tgw_peering]
# }


