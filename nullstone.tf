data "ns_workspace" "this" {}

data "ns_agent" "this" {}

locals {
  ns_agent_user_arn = data.ns_agent.this.aws_user_arn
}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

locals {
  tags          = data.ns_workspace.this.tags
  stack_name    = data.ns_workspace.this.stack_name
  block_ref     = data.ns_workspace.this.block_ref
  block_name    = data.ns_workspace.this.block_name
  env_name      = data.ns_workspace.this.env_name
  resource_name = "${data.ns_workspace.this.block_ref}-${random_string.resource_suffix.result}"

  match_labels = {
    "nullstone.io/stack" = local.stack_name
    "nullstone.io/app"   = local.app_name
    "nullstone.io/env"   = local.env_name
  }

  app_labels = {
    // k8s-recommended labels
    "app.kubernetes.io/name"       = local.block_name
    "app.kubernetes.io/version"    = local.app_version
    "app.kubernetes.io/component"  = ""
    "app.kubernetes.io/part-of"    = local.stack_name
    "app.kubernetes.io/managed-by" = "nullstone"
    // nullstone labels
    "nullstone.io/stack"     = local.stack_name
    "nullstone.io/app"       = local.block_name
    "nullstone.io/env"       = local.env_name
    "nullstone.io/block-ref" = local.block_ref
  }

  component_labels = {
    // k8s-recommended labels
    "app.kubernetes.io/name"       = local.block_name
    "app.kubernetes.io/version"    = ""
    "app.kubernetes.io/component"  = ""
    "app.kubernetes.io/part-of"    = data.ns_workspace.this.stack_name
    "app.kubernetes.io/managed-by" = "nullstone"
    // nullstone labels
    "nullstone.io/stack"     = local.stack_name
    "nullstone.io/block-ref" = local.block_ref
    "nullstone.io/app"       = data.ns_workspace.this.block_name
    "nullstone.io/block"     = local.block_name
    "nullstone.io/env"       = local.env_name
  }
}
