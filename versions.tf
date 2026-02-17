terraform {
  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.8"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
  }
}
