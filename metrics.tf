locals {
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

  base_metrics = []
}
