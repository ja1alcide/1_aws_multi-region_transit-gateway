terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # configuration_aliases = [aws]
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0"
    }
  }
}
