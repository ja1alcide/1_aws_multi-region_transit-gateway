# AWS VPC Networking Module

## Overview

This Terraform module deploys a highly configurable Virtual Private Cloud (VPC) on AWS. It is designed to be flexible, supporting dynamic subnet calculations (`cidrsubnet`), optional feature flags for cost-control (NAT Gateways), and automatic route table associations.

It allows you to define public and private network topologies purely through variable maps.

## Resources Created

* **VPC:** Custom CIDR block with DNS support enabled by default.
* **Subnets:** Dynamically created based on map configurations.
* **Gateways:**
* **Internet Gateway (IGW):** Created if `enable_igw` is true.
* **NAT Gateway & EIP:** Created if `enable_nat_gateway` is true.


* **Routing:**
    * Public Route Table (routes to IGW).
    * Private Route Table (routes to NAT GW if enabled, or local-only).
    * Automatic associations based on subnet type, routing table associations.



---

## Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc_networking"

  vpc_name    = "my-app-vpc"
  environment = "dev"
  owner       = "devops-team"
  vpc_cidr    = "10.0.0.0/16"

  # Feature Flags
  enable_igw         = true
  enable_nat_gateway = false

  # Subnet Configuration
  public_subnets_config = {
    "public-us-east-1a" = {
      az_index  = 0
      newbits   = 8
      netnum    = 1
      is_public = true
    }
  }
}

```

---

## Input Variables

### General Variables

| Name | Type | Description | Default | Required |
| --- | --- | --- | --- | --- |
| `vpc_name` | `string` | The Name tag for the VPC. | - | **Yes** |
| `environment` | `string` | Deployment environment (e.g., `dev`, `prod`). | - | **Yes** |
| `owner` | `string` | The owner of the infrastructure (for tagging). | - | **Yes** |
| `vpc_cidr` | `string` | The CIDR block for the VPC. | `"10.0.0.0/16"` | No |
| `tags` | `map(string)` | Additional tags to apply to resources. | `{}` | No |

### VPC Features

| Name | Type | Description | Default | Required |
| --- | --- | --- | --- | --- |
| `dns_support` | `bool` | Enable DNS support in the VPC. | `true` | No |
| `dns_hostname` | `bool` | Enable DNS hostnames in the VPC. | `true` | No |
| `enable_igw` | `bool` | Toggle creation of the Internet Gateway. | `true` | No |
| `enable_nat_gateway` | `bool` | Toggle creation of NAT Gateway + EIP. **Note:** Incurs AWS costs. | `false` | No |

### Subnet Configuration

The module uses `map(object)` to define subnets. The **Key** of the map becomes the Subnet Name.

#### `public_subnets_config`

Configuration for public-facing subnets.

* **Type:** `map(object)`
* **Structure:**
* `az_index` (number): Index of the Availability Zone (0 = first AZ, 1 = second AZ).
* `newbits` (number): Bits to add to VPC CIDR for the subnet mask.
* `netnum` (number): Unique network number for the subnet.
* `is_public` (bool): Flag to indicate public routing logic.



#### `private_subnets_config`

Configuration for internal subnets.

* **Type:** `map(object)`
* **Structure:**
* `az_index` (number): Index of the Availability Zone.
* `newbits` (number): Bits to add to VPC CIDR.
* `netnum` (number): Unique network number.
* `needs_nat_gw` (bool): If `true`, routes traffic to NAT Gateway (requires `enable_nat_gateway = true`).



---

## Outputs

|Name|Type|Description|
|---|---|---|
|`vpc_id`|`string`|The AWS ID of the created VPC.|
|`vpc_arn`|`string`|The AWS ARN of the created VPC.|
|`public_subnet_id`|`list(string)`|List of IDs for all created public subnets.|
|`private_subnet_id`|`list(string)`|List of IDs for all created private subnets.|
|`nat_eip_id`|`string`|The Allocation ID of the NAT Gateway EIP. Returns `null` if not created.|
|`public_rt_id`|`string`|The ID of the Public Route Table. Returns `null` if not created.|
|`private_nat_rt_id`|`string`|The ID of the Private Route Table. Returns `null` if not created.|
|`available_azs`|`list(string)`|A list of Availability Zone names available in the deployment region.|


---

## Internal Resource Reference

This section lists the specific Terraform resource names used within the module. This is useful for advanced operations like `terraform state` manipulation or imports.

| Resource Type | Internal Name | Description |
| --- | --- | --- |
| **VPC** | `aws_vpc.main` | The main VPC resource. |
| **Subnets (Public)** | `aws_subnet.public_subnets` | Map of public subnets (created via `for_each`). |
| **Subnets (Private)** | `aws_subnet.private_subnets` | Map of private subnets (created via `for_each`). |
| **Route Table (Public)** | `aws_route_table.public` | Route table for public subnets (IGW). |
| **Route Table (Priv)** | `aws_route_table.private_nat_access` | Route table for private subnets (NAT). |
| **Elastic IP** | `aws_eip.nat` | The EIP attached to the NAT Gateway. |
| **Data Source** | `data.aws_availability_zones.available` | The lookup for AZs in the region. |

> **Note:** Resources created with `for_each` (like subnets) will appear in the state as `aws_subnet.public_subnets["key_name"]`.

---

## Notes

* **CIDR Calculation:** This module relies on Terraform's `cidrsubnet` function. Ensure your `netnum` and `newbits` combinations do not result in overlapping CIDR blocks.
* **Cost Warning:** Enabling `enable_nat_gateway` will provision an Elastic IP and a NAT Gateway, which are billable AWS resources even if idle.
* **Listing Available Zones:** This module is designed to utilize Availability Zones based on their availability in the working region. To view the list of available Availability Zones run the command `terraform apply -refresh-only` in the CLI.

