
# Secure Cross-Region Medical Architecture (APPI-Compliant)

## Project Summary

This project implements a multi-region, compliance-driven infrastructure designed for a Japanese healthcare provider. To strictly adhere to Japan’s **Act on the Protection of Personal Information (APPI)**, which mandates that all Patient Health Information (PHI) must physically reside within Japan, this architecture establishes a "Data Authority" in Tokyo and a stateless "Compute Extension" in São Paulo.

## Architecture Overview

The system utilizes an asymmetric Hub-and-Spoke topology to balance global access with strict data residency.

- **Primary Region (Hub):** Tokyo (`ap-northeast-1`). This region hosts the primary VPC, the Transit Gateway Hub, and the **RDS Database**. It is the sole location for persistent PHI storage.
    
- **Secondary Region (Spoke):** São Paulo (`sa-east-1`). This region hosts a stateless compute environment for South American staff. It contains **no database** and retains no persistent patient data.
    
- **Network Connectivity:** Regions are connected via **AWS Transit Gateway Peering** over the AWS Global Backbone. This ensures all cross-region traffic is encrypted and routed privately, bypassing the public internet.
    
- **Global Ingress:** A single CloudFront distribution serves traffic globally, routing users to the nearest healthy compute node via Latency-Based Routing while enforcing WAF protection at the edge.
    

---

## Repository Organization

This project simulates a production DevOps environment where regions operate with **decoupled Terraform states**. Resources are segregated into region-specific directories to mimic independent regional deployment pipelines.

The terraform code for this lab's infrastructure can be found in the `/Terraform/` directory, and has the following overall layout:

```
.
├── 01.tokyo/
│   ├── 00.auth.tf
│   ├── 00.data.tf
│   ├── 01.tokyo_vpc-asg-alb.tf
│   ├── 02.roles_policies.tf
│   ├── 03.tokyo_secrets_parameters.tf
│   ├── 04.rds-db.tf
│   ├── 05.tokyo_vpc_endpoints_sg.tf
│   ├── 06.tokyo_sns_cloudwatch.tf
│   ├── 07.tokyo_waf-logs_alb-cloudtrail-logs_s3.tf
│   ├── 08.tokyo_alb-sns_cloudwatch.tf
│   ├── 09.route53.tf
│   ├── 10.cloudfront.tf
│   ├── 11.tgw_settings.tf
│   ├── 12.second_apply.tf
│   ├── app_code_tokyo.sh
│   ├── output.tf
│   └── var*.tf
├── 02.sao-paulo/
│   ├── 00.auth.tf
│   ├── 00.data.tf
│   ├── 01.sao-paulo_vpc-asg-alb.tf
│   ├── 02.roles_policies.tf
│   ├── 03.sao-paulo_secrets_parameters.tf
│   ├── 04.sao-paulo_vpc_endpoints_sg.tf
│   ├── 05.sao-paulo_sns_cloudwatch.tf
│   ├── 06.sao-paulo_alb-logs_s3.tf
│   ├── 07.sao-paulo_alb_cloudwatch.tf
│   ├── 08.route53.tf
│   ├── 09.tgw_settings.tf
│   ├── app_code_sao-paulo.sh
│   ├── output.tf
│   └── var*.tf
└── modules/
    ├── alb
    ├── asg_launch_template
    └── vpc_networking
```


---

#### Infrastructure as Code (IaC) Structure - Details

This repository is organized into distinct regional directories to maintain **state isolation** and modularity. Data is shared between regions using `terraform_remote_state`, where the `output.tf` of one region acts as the input for the other.

##### 1. Primary Region: Tokyo (`ap-northeast-1`)

_Acting as the Hub and Data Authority._

```
01.tokyo/
├── 00.auth.tf                     # Provider configuration (locked to ap-northeast-1)
├── 00.data.tf                     # Data sources (AMI lookups, Availability Zones)
├── 01.tokyo_vpc-asg-alb.tf        # Core Networking, ALB, and Auto Scaling Group
├── 02.roles_policies.tf           # IAM Roles for EC2 (SSM, CloudWatch, DB Access)
├── 03.tokyo_secrets...tf          # Secrets Manager (DB Creds) & SSM Parameters
├── 04.rds-db.tf                   # MySQL RDS Instance (PHI Storage - Tokyo Only)
├── 05.tokyo_vpc_endpoints...tf    # VPC Interface Endpoints (SSM, Logs, Secrets)
├── 06.tokyo_sns_cloudwatch.tf     # Monitoring & Alerting (SNS Topics, Alarms)
├── 07.tokyo_waf-logs...tf         # WAF Logging Configuration & S3 Bucket
├── 08.tokyo_alb_cloudwatch.tf     # ALB-specific CloudWatch Alarms
├── 09.route53.tf                  # DNS Records (Latency-based routing)
├── 10.cloudfront.tf               # Global CDN Distribution & WAF Association
├── 11.tgw_settings.tf             # TGW Hub Creation & Peering Requester
├── 12.second_apply.tf             # Cross-Region Routes etc. (Applied post-peering)
├── output.tf                      # EXPORTS: TGW ID, VPC CIDR, DB Endpoint
└── [variables]                    # Local configuration values
```

##### 2. Secondary Region: São Paulo (`sa-east-1`)

_Acting as the Spoke and Compute Extension._

```
02.sao-paulo/
├── 00.auth.tf                     # Provider configuration (locked to sa-east-1)
├── 00.data.tf                     # IMPORTS: Reads Tokyo state (TGW ID, DB Endpoint)
├── 01.sao-paulo_vpc-asg-alb.tf    # Stateless Compute Stack (No RDS)
├── 02.roles_policies.tf           # IAM Roles (Mirrors Tokyo but scoped to SP)
├── 03.sao-paulo_secrets...tf      # Replicates Secrets structure (no hard data)
├── 04.sao-paulo_vpc_endpoints...tf# Interface Endpoints for secure AWS service access
├── 05.sao-paulo_sns...tf          # Local Region Monitoring & Alerting
├── 06.sao-paulo_alb-logs...tf     # Local S3 Bucket for Access Logs
├── 07.sao-paulo_alb_cloudwatch.tf # ALB-specific CloudWatch Alarms
├── 08.route53.tf                  # DNS Records (Latency-based routing)
├── 09.tgw_settings.tf             # TGW Spoke Creation & Peering Accepter
├── output.tf                      # EXPORTS: TGW ID, VPC CIDR (for Tokyo routes)
└── [variables]                    # Local configuration values
```

##### 3. Shared Modules

_Centralized logic for consistent resource deployment._

```
modules/
├── alb/                           # Application Load Balancer Pattern
├── asg_launch_template/           # EC2 Launch Template & ASG Pattern
└── vpc_networking/                # Standardized VPC, Subnet, & Route Table Pattern
```

---

##### Cross-Region State Sharing

Because the regions are decoupled, they cannot directly reference each other's resource IDs. We solve this using the `terraform_remote_state` data source.

- **The Publisher (`output.tf`):**
    
    Each region exposes critical infrastructure IDs.
    
    - _Tokyo exports:_ `transit_gateway_id`, `rds_endpoint`, `vpc_cidr`
        
    - _São Paulo exports:_ `transit_gateway_id`, `vpc_cidr`
        
- **The Consumer (`00.data.tf`):**
    
    Each region reads the _other_ region's state file to fetch these values dynamically.
    
    - _Example:_ São Paulo uses `data.terraform_remote_state.tokyo.outputs.transit_gateway_id` to know which TGW to peer with.
        
    - _Example:_ Tokyo uses `data.terraform_remote_state.sao_paulo.outputs.vpc_cidr` to route return traffic correctly.


---

## Deployment Workflow

**Critical Deployment Note:** Due to the cross-region dependencies inherent in Transit Gateway Peering (Requester $\leftrightarrow$ Accepter), the infrastructure must be deployed in the following sequence:

### Phase 1: Tokyo Foundation (Hub Initialization)

Initialize the Primary region to establish the VPC, Database, and Transit Gateway Hub.

```bash
cd 01.tokyo
# Note: Ensure '12.second_apply.tf' is commented out or excluded during this phase
terraform init
terraform apply
```

### Phase 2: São Paulo Connection (Spoke Deployment)

Deploy the Secondary region. This configuration reads the Tokyo TGW ID from the remote state, creates the Spoke TGW, and **accepts** the peering request.

```bash
cd ../02.sao-paulo
terraform init
terraform apply
```

### Phase 3: Route Finalization (The Handshake)

Return to the Primary region to finalize the routing tables. Once the peering connection status is "Active," specific routes pointing to the São Paulo CIDR block are added.

```bash
cd ../01.tokyo
# Note: Uncomment '12.second_apply.tf' before running this command
terraform apply
```

---

## Technical Challenges & Resolutions

.....To be added soon.

---

## Compliance Statement

This architecture satisfies the data residency requirements of the **APPI**. All persistent storage (RDS, S3 Backups, EBS Snapshots) is physically constrained to the `ap-northeast-1` region. The `sa-east-1` region operates purely as a transient compute layer, utilizing the AWS Backbone for encrypted data retrieval and processing without local persistence.

----
This is a draft to be updated soon.# 1_aws_multi-region_transit-gateway
# 1_aws_multi-region_transit-gateway
