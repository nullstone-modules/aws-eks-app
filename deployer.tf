// This role allows the Nullstone agent to perform deployments to EKS.

resource "aws_iam_role" "deployer" {
  name               = "deployer-${local.resource_name}"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.deployer_assume.json
}

data "aws_iam_policy_document" "deployer_assume" {
  statement {
    effect  = "Allow"

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