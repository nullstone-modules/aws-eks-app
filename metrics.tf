locals {
  # Assumes the amazon-cloudwatch-observability EKS add-on is installed and reports
  # PodName as the controller (deployment) name. If a cluster is configured to report
  # PodName differently (e.g., ReplicaSet or full pod name), these queries return empty
  # and need to be revisited (e.g., switch to a SEARCH expression with substring match).
  pod_dims = tomap({
    "ClusterName" = local.cluster_name
    "Namespace"   = local.app_namespace
    "PodName"     = local.app_name
  })

  metrics_mappings = concat(local.base_metrics, local.cap_metrics)

  cap_metrics = [
    for m in local.capabilities.metrics : {
      name = m.name
      type = m.type
      unit = m.unit

      mappings = {
        for metric_id, mapping in jsondecode(lookup(m, "mappings", "{}")) : metric_id => {
          account_id        = mapping.account_id
          dimensions        = mapping.dimensions
          stat              = lookup(mapping, "stat", null)
          namespace         = lookup(mapping, "namespace", null)
          metric_name       = lookup(mapping, "metric_name", null)
          expression        = lookup(mapping, "expression", null)
          hide_from_results = lookup(mapping, "hide_from_results", null)
        }
      }
    }
  ]

  # Container Insights enhanced observability publishes pod_cpu_* in millicores and
  # pod_memory_* in bytes. Raw metrics are hidden; visible mappings divide to vCPU and MiB.
  base_metrics = [
    {
      name = "app/cpu"
      type = "usage"
      unit = "vCPU"

      mappings = {
        cpu_reserved_raw = {
          account_id        = local.account_id
          stat              = "Average"
          namespace         = "ContainerInsights"
          metric_name       = "pod_cpu_request"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        cpu_reserved = {
          account_id = local.account_id
          dimensions = {}
          expression = "cpu_reserved_raw / 1000"
        }
        cpu_avg_raw = {
          account_id        = local.account_id
          stat              = "Average"
          namespace         = "ContainerInsights"
          metric_name       = "pod_cpu_usage_total"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        cpu_average = {
          account_id = local.account_id
          dimensions = {}
          expression = "cpu_avg_raw / 1000"
        }
        cpu_min_raw = {
          account_id        = local.account_id
          stat              = "Minimum"
          namespace         = "ContainerInsights"
          metric_name       = "pod_cpu_usage_total"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        cpu_min = {
          account_id = local.account_id
          dimensions = {}
          expression = "cpu_min_raw / 1000"
        }
        cpu_max_raw = {
          account_id        = local.account_id
          stat              = "Maximum"
          namespace         = "ContainerInsights"
          metric_name       = "pod_cpu_usage_total"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        cpu_max = {
          account_id = local.account_id
          dimensions = {}
          expression = "cpu_max_raw / 1000"
        }
      }
    },
    {
      name = "app/memory"
      type = "usage"
      unit = "MiB"

      mappings = {
        memory_reserved_raw = {
          account_id        = local.account_id
          stat              = "Average"
          namespace         = "ContainerInsights"
          metric_name       = "pod_memory_request"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        memory_reserved = {
          account_id = local.account_id
          dimensions = {}
          expression = "memory_reserved_raw / 1048576"
        }
        memory_avg_raw = {
          account_id        = local.account_id
          stat              = "Average"
          namespace         = "ContainerInsights"
          metric_name       = "pod_memory_working_set"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        memory_average = {
          account_id = local.account_id
          dimensions = {}
          expression = "memory_avg_raw / 1048576"
        }
        memory_min_raw = {
          account_id        = local.account_id
          stat              = "Minimum"
          namespace         = "ContainerInsights"
          metric_name       = "pod_memory_working_set"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        memory_min = {
          account_id = local.account_id
          dimensions = {}
          expression = "memory_min_raw / 1048576"
        }
        memory_max_raw = {
          account_id        = local.account_id
          stat              = "Maximum"
          namespace         = "ContainerInsights"
          metric_name       = "pod_memory_working_set"
          dimensions        = local.pod_dims
          hide_from_results = true
        }
        memory_max = {
          account_id = local.account_id
          dimensions = {}
          expression = "memory_max_raw / 1048576"
        }
      }
    }
  ]
}
