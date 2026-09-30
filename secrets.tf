resource "aws_secretsmanager_secret" "app_secret" {
  for_each = data.ns_env_layout.this.managed_secret_keys

  name_prefix             = "${local.block_name}/${each.value}/"
  tags                    = local.tags
  kms_key_id              = module.scaffold.kms_alias_arn
  recovery_window_in_days = 0 // force delete so that re-adding the secret doesn't cause issues

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  for_each = data.ns_env_layout.this.managed_secret_keys

  secret_id     = aws_secretsmanager_secret.app_secret[each.value].id
  secret_string = data.ns_env_values.this.secrets[each.value]

  lifecycle {
    create_before_destroy = true
  }
}

// The following is used to cause app redeployments when secrets change
// We do this by annotating the deployment spec with a checksum of `map { secret_key => secret_version }`
// This works because any time a secret value changes, the "latest" version changes
locals {
  secrets_checksum = sha256(jsonencode(merge(
    { for key, secret in data.aws_secretsmanager_secret_version.unmanaged : key => secret.version_id },
    { for key, secret in aws_secretsmanager_secret_version.app_secret : key => secret.version_id },
  )))
}

data "aws_secretsmanager_secret_version" "unmanaged" {
  for_each = data.ns_env_layout.this.unmanaged_secret_keys

  secret_id = data.ns_env_values.this.unmanaged_secret_refs[each.value]
}

locals {
  // all_secrets is a map of name => secret arn in AWS Secrets Manager
  // This is keyed from `ns_env_layout` so that the keys are known at plan time
  all_secrets = merge(
    { for key in data.ns_env_layout.this.unmanaged_secret_keys : key => data.ns_env_values.this.unmanaged_secret_refs[key] },
    { for key, secret in aws_secretsmanager_secret.app_secret : key => secret.arn },
  )

  app_secret_store_name = "${local.app_name}-secrets"
}

// SecretProviderClass tells the CSI driver which Secrets Manager secrets to fetch
// and syncs them into a K8s Secret (local.app_secret_store_name) so they can be
// referenced as env vars via secretKeyRef in the pod spec.
resource "kubernetes_manifest" "secret_provider_class" {
  count = length(data.ns_env_layout.this.all_secret_keys) > 0 ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"

    metadata = {
      name      = local.app_name
      namespace = local.app_namespace
      labels    = local.component_labels
    }

    spec = {
      provider = "aws"

      parameters = {
        usePodIdentity = true
        // Each secret gets its own Secrets Manager secret; objectAlias becomes
        // the filename under the mount path and the key in the synced K8s Secret.
        objects = yamlencode([
          for key, arn in nonsensitive(local.all_secrets) : {
            objectName  = arn
            objectType  = "secretsmanager"
            objectAlias = key
          }
        ])
      }

      secretObjects = [
        {
          secretName = local.app_secret_store_name
          type       = "Opaque"
          data = [
            for key in tolist(data.ns_env_layout.this.all_secret_keys) : {
              objectName = key // matches objectAlias above
              key        = key
            }
          ]
        }
      ]
    }
  }
}
