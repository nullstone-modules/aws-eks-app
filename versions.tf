terraform {
  required_version = ">= 1.11.0"

  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.8.3"
    }
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}
