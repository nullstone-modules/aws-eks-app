resource "aws_iam_role_policy" "app" {
  role   = module.scaffold.app_role.name
  policy = data.aws_iam_policy_document.app.json
}

data "aws_iam_policy_document" "app" {
  statement {
    sid       = "AllowPassRoleToECS"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [module.scaffold.app_role.arn]
  }

  dynamic "statement" {
    for_each = length(local.all_secret_keys) > 0 ? [1] : []

    content {
      sid       = "AllowReadSecrets"
      effect    = "Allow"
      resources = values(local.all_secrets)

      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "kms:Decrypt"
      ]
    }
  }
}

resource "kubernetes_service_account_v1" "app" {
  metadata {
    namespace = local.app_namespace
    name      = local.app_name
    labels    = local.component_labels

    annotations = local.use_irsa ? {
      // IRSA: indicates which AWS IAM role this kubernetes service account can impersonate
      "eks.amazonaws.com/role-arn" = module.scaffold.app_role.arn
    } : {}
  }

  automount_service_account_token = true
}
