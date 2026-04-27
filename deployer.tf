// This role allows the Nullstone agent to perform deployments to EKS.

resource "aws_iam_role" "deployer" {
  name               = "deployer-${local.resource_name}"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.deployer_assume.json
}

data "aws_iam_policy_document" "deployer_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity",
    ]

    principals {
      type        = "AWS"
      identifiers = [local.ns_agent_user_arn]
    }
  }
}

resource "aws_iam_role_policy" "deployer" {
  role   = aws_iam_role.deployer.name
  policy = data.aws_iam_policy_document.deployer.json
}

data "aws_iam_policy_document" "deployer" {
  statement {
    sid       = "AllowDescribeCluster"
    effect    = "Allow"
    resources = [local.cluster_arn]

    actions = [
      "eks:DescribeCluster",
      "eks:AccessKubernetesApi",
    ]
  }
}

// Map the deployer IAM role to a K8s username via EKS Access Entry.
// An intercepted STS token can only call eks:DescribeCluster (to connect) plus
// whatever the K8s RBAC Role below allows — nothing more.
resource "aws_eks_access_entry" "deployer" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.deployer.arn
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "deployer_edit" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.deployer.arn
  policy_arn    = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [local.kubernetes_namespace]
  }

  depends_on = [aws_eks_access_entry.deployer]
}

// Wildcard read in the namespace so kubectl describe / rollout monitoring can
// resolve Event involvedObjects whose kind doesn't map cleanly via RESTMapper.
// The named edit policy above doesn't match an unknown resource type.
resource "kubernetes_role" "deployer_describe" {
  metadata {
    name      = "deployer-describe-${local.resource_name}"
    namespace = local.kubernetes_namespace
    labels    = local.tags
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "deployer_describe" {
  metadata {
    name      = "deployer-describe-${local.resource_name}"
    namespace = local.kubernetes_namespace
    labels    = local.tags
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.deployer_describe.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = aws_iam_role.deployer.arn
    api_group = "rbac.authorization.k8s.io"
  }
}