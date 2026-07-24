# 0.3.0 (Jul 24, 2026)
* Added `var.rolling_update_strategy` (default `max_surge = "1"`, `max_unavailable = "0"`; set `null` for the Kubernetes default). **This changes rollout behavior** — previously the strategy was hardcoded to 25% surge / 25% unavailable. The new default never reduces serving capacity mid-rollout, at the cost of slower rollouts for large replica counts.
* Added `var.termination_grace_seconds` (default 30). The effective grace period is the larger of this and any capability's `deployment_overrides.termination_grace_period_seconds`.
* Added a PodDisruptionBudget (`minAvailable = replicas - 1`) when `replicas >= 2` so voluntary disruptions can never take down the last ready replica.
* Added capability output support for `deployment_overrides`, configuring `preStop` and `terminationGracePeriodSeconds` from an attached Load Balancer for zero-downtime rollouts.
* Added capability output support for `resource_limits`, `node_selectors`, `tolerations`, and `topology_spread_constraints`.
* Extended resources from capability `resource_limits` (e.g. `nvidia.com/gpu`) are merged into the main container's `resources.limits` alongside `max_cpu`/`max_memory`.
* Topology spread constraints from capabilities get the app's pod selector (`match_labels`) injected automatically.
* Added the `secret` volume type to the capability `volumes` contract.

# 0.2.1 (Jul 15, 2026)
* Added `image_repo_name` to capability `app_metadata`.

# 0.2.0 (Jun 19, 2026)
* Upgraded `nullstone-io/ns` provider to `~> 0.11.0`.
* Used `aws_tags` from `data.ns_workspace` to tag all resources via provider `default_tags`.

# 0.1.4 (Jun 10, 2026)
* Upgraded terraform providers.

# 0.1.3 (May 28, 2026)
* Fixed secrets interpolation issues by upgrading nullstone terraform provider.

# 0.1.2 (May 1, 2026)
* Added `nullstone.io/app` label to components.

# 0.1.1 (May 1, 2026)
* Added cpu and memory to metrics in dashboard.

# 0.1.0 (Apr 29, 2026)
* Initial release
