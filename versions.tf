terraform {
  required_providers {
    ns = {
      source  = "nullstone-io/ns"
      version = "~> 0.9.0"
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
