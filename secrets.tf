resource "aws_secretsmanager_secret" "app_secret" {
  for_each = local.managed_secret_keys

  name_prefix             = "${local.block_name}/${each.value}/"
  tags                    = local.tags
  kms_key_id              = aws_kms_alias.this.arn
  recovery_window_in_days = 0 // force delete so that re-adding the secret doesn't cause issues

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  for_each = local.managed_secret_keys

  secret_id     = aws_secretsmanager_secret.app_secret[each.value].id
  secret_string = local.managed_secret_values[each.value]

  lifecycle {
    create_before_destroy = true
  }
}

// The following is used to cause app redeployments when secrets change
// We do this by annotating the deployment spec with a checksum of `map { secret_key => secret_version }`
// This works because any time a secret value changes, the "latest" version changes
locals {
  managed_secrets_versions = {
    for key in local.managed_secret_keys : key => aws_secretsmanager_secret_version.app_secret[key].arn
  }
  unmanaged_secrets_versions = {
    for key in local.unmanaged_secret_keys : key => data.aws_secretsmanager_secret_version.unmanaged[key].arn
  }
  secrets_checksum = sha256(jsonencode(merge(local.unmanaged_secrets_versions, local.managed_secrets_versions)))
}

data "aws_secretsmanager_secret_version" "unmanaged" {
  for_each = local.unmanaged_secrets

  secret_id = each.value
}
