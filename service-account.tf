resource "aws_iam_role" "app" {
  name               = local.resource_name
  tags               = local.tags
  assume_role_policy = local.use_irsa ? data.aws_iam_policy_document.app_irsa_assume.json : data.aws_iam_policy_document.app_assume.json
}

// Enable Pod Identity Agent to grant an IAM role to the Kubernetes service account
data "aws_iam_policy_document" "app_assume" {
  statement {
    sid    = "AllowEKSAuthToAssumeRoleForPodIdentity"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

locals {
  oidc_issuer_noproto = replace(local.cluster_oidc_issuer, "https://", "")
}

// EKS Fargate clusters cannot use pod identity agent to gain an IAM role from a Kubernetes service account
// Instead, we use the cluster's OpenId provider to grant the IAM role
data "aws_iam_policy_document" "app_irsa_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.cluster_openid_provider_arn]
    }

    # Lock to this service account only
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_noproto}:sub"
      values   = ["system:serviceaccount:${local.app_namespace}:${local.app_name}"]
    }

    # Standard audience restriction
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_noproto}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "app" {
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app.json
}

data "aws_iam_policy_document" "app" {
  statement {
    sid       = "AllowPassRoleToECS"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.app.arn]
  }

  dynamic "statement" {
    for_each = length(local.all_secret_keys) > 0 ? [1] : []

    content {
      sid       = "AllowReadSecrets"
      effect    = "Allow"
      resources = values(local.all_secrets)

      actions = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
    }
  }
}

resource "aws_eks_pod_identity_association" "app" {
  count = local.use_irsa ? 0 : 1

  cluster_name    = local.cluster_name
  namespace       = local.app_namespace
  service_account = local.app_name
  role_arn        = aws_iam_role.app.arn
}

resource "kubernetes_service_account_v1" "app" {
  metadata {
    namespace = local.app_namespace
    name      = local.app_name
    labels    = local.component_labels

    annotations = local.use_irsa ? {
      // IRSA: indicates which AWS IAM role this kubernetes service account can impersonate
      "eks.amazonaws.com/role-arn" = aws_iam_role.app.arn
    } : {}
  }

  automount_service_account_token = true
}
