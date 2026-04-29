data "ns_app_env" "this" {
  stack_id = data.ns_workspace.this.stack_id
  app_id   = data.ns_workspace.this.block_id
  env_id   = data.ns_workspace.this.env_id
}

locals {
  app_namespace = local.kubernetes_namespace
  app_name      = data.ns_workspace.this.block_name
  app_version   = data.ns_app_env.this.version
}

locals {
  app_metadata = tomap({
    // Inject app metadata into capabilities here (e.g. security_group_name, role_name)
    security_group_id  = aws_security_group.this.id
    role_name          = module.scaffold.app_role.name
    main_container     = local.main_container_name
    container_port     = var.container_port
    service_port       = var.service_port
    internal_subdomain = var.service_port == 0 ? "" : "${local.block_name}.${local.kubernetes_namespace}.svc.cluster.local"
  })
}
