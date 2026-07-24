# EKS App

Runs a long-running container service (API, web app, background worker) on AWS EKS as a Kubernetes `Deployment` with a `ClusterIP` `Service`.

For one-shot or scheduled jobs, use the EKS Job module instead.

## When to use

Pick this module when:
- You want a Kubernetes-native runtime on AWS and your platform team has standardized on EKS.
- The workload is always-on (handles requests, processes a queue, runs a worker loop).

If you don't need Kubernetes, `aws-fargate-service` is simpler. If you need GPU/scheduled batch, use `aws-eks-job`.

## Platform

Backed by [Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html). The module assumes the cluster is provisioned and connected via the `cluster-namespace` connection (which itself flows through to the `cluster` and `network` connections). Per-app resources land in the namespace selected by that connection.

## Container image

By default, the module provisions an ECR repository and the `image_repo_url` output points at it. Use `nullstone deploy --version=<tag>` to roll a new image; the deployment redeploys with `image:<tag>`.

To use an externally managed image, set `image_url` to a fully qualified registry URL. You can still pass `--version` to select a tag.

## Compute & scheduling

| Variable | Default | Notes |
|----------|---------|-------|
| `cpu` / `memory` | `0.5` / `512Mi` | Pod resource **requests**. Used by the scheduler. |
| `max_cpu` / `max_memory` | unset | Pod resource **limits**. Unset means no limit (memory limit = no OOMKill). |
| `replicas` | `1` | Static replica count. Pair with a cluster-level HPA capability if you need autoscaling. |
| `command` | image default | Override the container `CMD`. Each token is one list element. |
| `container_port` | `8080` | Port the container listens on. Must be ≥1024 (no privileged ports). |
| `service_port` | `80` | Port other services use to reach this app via `<app>:<service_port>`. Set to `0` to disable the `Service` entirely. |
| `rolling_update_strategy` | `max_surge = "1"`, `max_unavailable = "0"` | Rollout pacing. Set to `null` for the Kubernetes default (25% / 25%). |
| `termination_grace_seconds` | `30` | Seconds after SIGTERM before the pod is force-killed. |

The deployment keeps the last 10 revisions.

Capabilities can further constrain scheduling through the `resource_limits`, `node_selectors`, `tolerations`, and `topology_spread_constraints` outputs — see [Capabilities](#capabilities). Extended resources such as `nvidia.com/gpu` arrive that way and are merged into the container's `resources.limits` alongside `max_cpu` / `max_memory`.

## Zero-downtime rollouts

The defaults (`max_surge = "1"`, `max_unavailable = "0"`) guarantee serving capacity never drops during a rollout: a new pod becomes ready before an old one is removed.

Closing the remaining gap requires coordinating pod termination with load balancer deprogramming. An attached load balancer capability can supply a `deployment_overrides` output with:

- `pre_stop_seconds` — the container gets a `preStop` hook that sleeps this long, holding the listener open while the load balancer removes the endpoint. Without it, in-flight requests can land on a terminating pod and surface as connection resets.
- `termination_grace_period_seconds` — the effective grace period is the **larger** of this and `var.termination_grace_seconds`.

> **No AWS capability produces `deployment_overrides` today.** The consumer side is wired and ready, but until a load balancer capability emits it, `preStop` is not applied and only the surge/unavailable guarantee is in effect.

When `replicas >= 2`, the module also emits a PodDisruptionBudget with `minAvailable: replicas - 1`, so voluntary disruptions (node drains, node group upgrades) can never take down the last ready replica. Single-replica apps get no PDB — `minAvailable: 0` protects nothing, and `minAvailable: 1` would block node drains entirely.

### Handling SIGTERM in your application

For any of this to help, your app must stop accepting new work on SIGTERM, finish in-flight requests, then exit. An app that ignores SIGTERM will be force-killed at the end of the grace period regardless of these settings.

## Networking

- A `ClusterIP` `Service` named after the app is created in the namespace whenever both `service_port` and `container_port` are non-zero. Other workloads reach it at `<app>.<namespace>.svc.cluster.local:<service_port>`.
- Each pod is bound to a per-app `aws_security_group` via a `SecurityGroupPolicy` (VPC CNI security groups for pods). The SG allows:
  - Egress: DNS (TCP/UDP 53) and HTTPS (443) to anywhere; all traffic within the VPC CIDR.
  - Ingress: `service_port` from private and public subnet CIDRs in the connected VPC.
- Set `disable_security_group = true` to skip applying the `SecurityGroupPolicy` (useful when ENIs per node are constrained). Note: the SG itself is still created so capabilities can attach rules to it.

The module emits `private_urls` based on the in-cluster service hostname. Public URLs come from ingress capabilities.

## Public access

This module does not provision public ingress on its own. Attach an Ingress capability (e.g. ALB, NLB, or a Kubernetes-native ingress) to expose the service externally. Public hostnames added by capabilities flow through the `public_urls` / `public_hosts` outputs and into the `NULLSTONE_PUBLIC_HOSTS` environment variable.

## Identity & permissions (Pod Identity / IRSA)

The pod runs as a Kubernetes `ServiceAccount` named after the app. AWS API access is granted via:
- **EKS Pod Identity** by default.
- **IRSA** if the connected cluster reports `use_irsa = true`. In that case the service account is annotated with `eks.amazonaws.com/role-arn` and the OIDC trust is wired through the scaffold.

Capabilities can attach IAM policies to the app role (`module.scaffold.app_role`) to grant access to S3, DynamoDB, etc.

## Environment variables

`var.env_vars` is a plain `map(string)` injected as container env. Standard variables are injected automatically:

| Var | Source |
|-----|--------|
| `NULLSTONE_STACK`, `NULLSTONE_APP`, `NULLSTONE_ENV` | Workspace |
| `NULLSTONE_VERSION`, `NULLSTONE_COMMIT_SHA` | Latest deploy |
| `NULLSTONE_PUBLIC_HOSTS`, `NULLSTONE_PRIVATE_HOSTS` | Comma-separated list from URL outputs |
| `AWS_REGION` | Module region |

Values support Nullstone Handlebar interpolation — including K8s-native references:
- `{{ secret(name) }}` — pulls an existing AWS Secrets Manager secret ARN you own.
- `{{ k8s.field(apiVersion, fieldPath) }}` — `valueFrom.fieldRef`.
- `{{ k8s.configMap(key, name[, optional]) }}` — `valueFrom.configMapKeyRef`.
- `{{ k8s.resourceField(resource[, container, divisor]) }}` — `valueFrom.resourceFieldRef`.
- `{{ k8s.fileKey(key, path, volumeName) }}` — `valueFrom.fileKeyRef` (Kubernetes 1.34+ with the `EnvFiles` feature gate).

## Secrets

`var.secrets` is a sensitive `map(string)`. Each entry is created as an AWS Secrets Manager secret encrypted with the module's KMS key. Secrets are mounted into the pod via the [Secrets Store CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/) using the AWS provider, then synced into a Kubernetes `Secret` named `<app>-secrets` and exposed as env vars.

A checksum of secret versions is annotated on the pod template so editing a secret triggers a rollout.

> **Cluster prerequisites:** the [Secrets Store CSI driver](https://secrets-store-csi-driver.sigs.k8s.io/) and the [AWS provider](https://github.com/aws/secrets-store-csi-driver-provider-aws) must already be installed in the cluster.

## Probes

Startup, readiness, and liveness probes are configured via capabilities (`startup_probes`, `readiness_probes`, `liveness_probes`) and support `exec`, `grpc`, `http_get`, and `tcp_socket` actions. There is no module variable for probes today — wire them through a probe capability or a custom capability with the appropriate output.

## Volumes

Capabilities can mount volumes via the `volumes` and `volume_mounts` outputs. Supported volume sources: `empty_dir`, `persistent_volume_claim`, `host_path`, `secret`. The CSI-mounted secrets volume (`/mnt/secrets-store`) is added automatically when secrets are present.

## Logs & metrics

| Output | Provider | Notes |
|--------|----------|-------|
| `log_provider` | `eks` | Use `nullstone logs` to stream pod logs. |
| `log_reader` | IAM role | EKS access entry with `view` policy and CloudWatch log read. |
| `metrics_provider` | `cloudwatch` | Capabilities emit metric mappings via the `metrics` output. |
| `metrics_reader` | IAM role | Read access for the Nullstone monitoring page. |

## Capabilities

This module consumes the following capability outputs:

| Output | Purpose |
|--------|---------|
| `env`, `secrets` | Inject env vars / secrets, prefixed by capability scope. |
| `private_urls`, `public_urls` | Roll up to module outputs. |
| `metrics` | Display on the Nullstone monitoring page. |
| `volumes`, `volume_mounts` | Attach K8s volumes to the pod. |
| `startup_probes`, `readiness_probes`, `liveness_probes` | Container probe configuration. |
| `service_annotations` | Annotations on the `Service` resource (e.g. AWS Load Balancer Controller hints). |
| `deployment_annotations` | Annotations on the `Deployment` resource. |
| `deployment_overrides` | `pre_stop_seconds` and `termination_grace_period_seconds` for zero-downtime termination. Only the first entry is read. |
| `resource_limits` | Extended resources (e.g. `nvidia.com/gpu`) merged into the container's `resources.limits`. |
| `node_selectors` | Constrain scheduling to nodes carrying these labels. |
| `tolerations` | Allow scheduling onto tainted nodes. |
| `topology_spread_constraints` | Spread replicas across failure domains. The pod selector is injected automatically. |

## Outputs (developer-facing)

- `service_name`, `service_namespace` — Kubernetes coordinates of the deployment.
- `image_repo_url` — ECR URL to push images to (when the module manages the repo).
- `image_pusher`, `deployer`, `log_reader`, `metrics_reader` — IAM roles for CI/CD and observability.
- `app_security_group_id` — attach extra SG rules through capabilities.
- `private_urls` / `public_urls` / `private_hosts` / `public_hosts` — service reachability.
