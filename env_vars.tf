// Environment Variables and Secrets
//
// This file is responsible for aggregating environment variables and secrets from multiple sources
// - Standard Environment Variables (NULLSTONE_APP, etc.)
// - AWS Environment Variables (AWS_REGION, etc.)
// - User Input (var.env_vars, var.secrets)
// - Capability Outputs (output.env, output.secrets)
//
// For secrets, we need to do the following:
// 1. Add secrets to GCP secrets manager (var.secrets, local.capabilities.secrets)
//   -> Don't add secret for `{{ secret(...) }}` -- these are secrets that already exist in GCP
// 2. Add app access to GCP secrets manager secrets (var.secrets, local.capabilities.secrets)
// 3. Add k8s secret referencing associated GCP secrets manager secrets
// 4. Add env var to pod referencing k8s secret

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = <<EOF
The environment variables to inject into the service.
These are typically used to configure a service per environment.
It is dangerous to put sensitive information in this variable because they are not protected and could be unintentionally exposed.
EOF
}

variable "secrets" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = <<EOF
The sensitive environment variables to inject into the service.
These are typically used to configure a service per environment.
EOF
}

locals {
  standard_env_vars = tomap({
    NULLSTONE_STACK         = data.ns_workspace.this.stack_name
    NULLSTONE_APP           = data.ns_workspace.this.block_name
    NULLSTONE_ENV           = data.ns_workspace.this.env_name
    NULLSTONE_VERSION       = data.ns_app_env.this.version
    NULLSTONE_COMMIT_SHA    = data.ns_app_env.this.commit_sha
    NULLSTONE_PUBLIC_HOSTS  = join(",", local.public_hosts)
    NULLSTONE_PRIVATE_HOSTS = join(",", local.private_hosts)
  })
  aws_env_vars = tomap({
    AWS_REGION = local.region
  })
}

// ns_env_layout classifies secrets using keys only, so the set of secrets is known at plan time
// - managed_secret_keys: secrets that this module adds to AWS Secrets Manager
// - unmanaged_secret_keys: references to existing secrets `{{ secret(...) }}`
data "ns_env_layout" "this" {
  platform               = "aws_eks"
  standard_keys          = keys(local.standard_env_vars)
  cloud_keys             = keys(local.aws_env_vars)
  capability_env_keys    = [for e in local.capabilities.env : { capability = e.capability, name = e.name }]
  capability_secret_keys = [for s in local.capabilities.secrets : { capability = s.capability, name = s.name }]
  capability_prefixes    = local.cap_prefixes
  user_env               = var.env_vars
  user_secret_keys       = nonsensitive(keys(var.secrets))
}

data "ns_env_values" "this" {
  platform            = "aws_eks"
  standard            = local.standard_env_vars
  cloud               = local.aws_env_vars
  capability_env      = local.capabilities.env
  capability_secrets  = local.capabilities.secrets
  capability_prefixes = local.cap_prefixes
  user_env            = var.env_vars
  user_secrets        = var.secrets
}

// ns_env_platform_data records where each managed secret lives so Nullstone can display the environment
// The pod reads every secret from the k8s Secret that the CSI driver syncs from AWS Secrets Manager
data "ns_env_platform_data" "this" {
  values = data.ns_env_values.this.platform_data
  k8s_secret_refs = {
    for key in data.ns_env_layout.this.managed_secret_keys : key => { name = local.app_secret_store_name, key = key }
  }
}
