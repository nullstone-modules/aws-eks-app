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
  tags          = data.ns_workspace.this.aws_tags
  stack_name    = data.ns_workspace.this.stack_name
  block_ref     = data.ns_workspace.this.block_ref
  block_name    = data.ns_workspace.this.block_name
  env_name      = data.ns_workspace.this.env_name
  resource_name = "${data.ns_workspace.this.block_ref}-${random_string.resource_suffix.result}"

  app_labels = merge(data.ns_workspace.this.k8s_labels, {
    "nullstone.io/app"          = local.app_name
    "app.kubernetes.io/version" = local.app_version
  })

  component_labels = merge(data.ns_workspace.this.k8s_labels, {
    "nullstone.io/app" = local.app_name
  })

  match_labels = {
    "nullstone.io/stack" = local.stack_name
    "nullstone.io/app"   = local.app_name
    "nullstone.io/env"   = local.env_name
  }
}
