data "ns_connection" "cluster_namespace" {
  name     = "cluster-namespace"
  contract = "cluster-namespace/aws/k8s:eks"
}

data "ns_connection" "cluster" {
  name     = "cluster"
  contract = "cluster/aws/k8s:eks"
  via      = data.ns_connection.cluster_namespace.name
}

locals {
  cluster_name                = data.ns_connection.cluster_namespace.outputs.cluster_name
  kubernetes_namespace        = data.ns_connection.cluster_namespace.outputs.kubernetes_namespace
  cluster_endpoint            = data.ns_connection.cluster_namespace.outputs.cluster_endpoint
  cluster_ca_certificate      = data.ns_connection.cluster_namespace.outputs.cluster_ca_certificate
  cluster_oidc_issuer         = try(data.ns_connection.cluster_namespace.outputs.cluster_oidc_issuer, "")
  cluster_openid_provider_arn = try(data.ns_connection.cluster_namespace.outputs.cluster_openid_provider_arn, "")
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
}
