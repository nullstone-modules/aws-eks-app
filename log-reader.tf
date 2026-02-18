// This role allows reading Kubernetes resources (pods, logs, events, etc.) in EKS.

resource "aws_iam_role" "log_reader" {
  name               = "log-reader-${local.resource_name}"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.log_reader_assume.json
}

data "aws_iam_policy_document" "log_reader_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.ns_agent_user_arn]
    }
  }
}

resource "aws_iam_role_policy" "log_reader" {
  role   = aws_iam_role.log_reader.name
  policy = data.aws_iam_policy_document.log_reader.json
}

data "aws_iam_policy_document" "log_reader" {
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

resource "aws_eks_access_entry" "log_reader" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.log_reader.arn
  type          = "STANDARD"
  tags          = local.tags
}

resource "aws_eks_access_policy_association" "log_reader_view" {
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.log_reader.arn
  policy_arn    = "arn:${local.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [local.kubernetes_namespace]
  }

  depends_on = [aws_eks_access_entry.log_reader]
}
