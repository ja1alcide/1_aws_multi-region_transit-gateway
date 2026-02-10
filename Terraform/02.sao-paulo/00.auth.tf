terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.5"
    }
  }
  required_version = ">1.10"
}

provider "aws" {
  region = "sa-east-1" # default region
}

provider "aws" {
  alias  = "sao-paulo"
  region = "sa-east-1" # Sao Paulo
}

provider "aws" {
  alias  = "us_e_1"
  region = "us-east-1" # N. Virgina fo resources exclusive to this region.
}
