locals {
  has_service  = var.service_port == 0 || var.container_port == 0 ? false : true
  service_name = !local.has_service ? "" : local.app_name

  service_annotations = tomap({ for ann in local.capabilities.service_annotations : ann.name => ann.value })
}

resource "kubernetes_service_v1" "this" {
  count = local.has_service ? 1 : 0

  metadata {
    name        = local.service_name
    namespace   = local.app_namespace
    labels      = local.component_labels
    annotations = local.service_annotations
  }

  spec {
    type = "ClusterIP"

    selector = local.match_labels

    port {
      port        = var.service_port
      target_port = var.container_port
    }
  }
}
