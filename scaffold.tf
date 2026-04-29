module "scaffold" {
  source = "registry.terraform.io/nullstone-modules/eks-appscaffold/aws"

  region                          = local.region
  account_id                      = local.account_id
  partition                       = local.partition
  app_name                        = local.app_name
  block_ref                       = local.block_ref
  resource_suffix                 = random_string.resource_suffix.result
  tags                            = local.tags
  image_url                       = var.image_url
  cluster_name                    = local.cluster_name
  cluster_arn                     = local.cluster_arn
  kubernetes_namespace            = local.kubernetes_namespace
  kubernetes_service_account_name = local.app_name
  use_irsa                        = local.use_irsa
  cluster_oidc_issuer             = local.cluster_oidc_issuer
  cluster_openid_provider_arn     = local.cluster_openid_provider_arn
  op_assumer_arns                 = [local.ns_agent_user_arn]
}

locals {
  image_url = module.scaffold.repository_url
}

// State migration for resources extracted into the eks-appscaffold module.
// These can be removed once every environment has been successfully applied
// against the new module layout.

moved {
  from = aws_kms_key.this
  to   = module.scaffold.aws_kms_key.this
}

moved {
  from = aws_kms_alias.this
  to   = module.scaffold.aws_kms_alias.this
}

moved {
  from = aws_ecr_repository.this[0]
  to   = module.scaffold.aws_ecr_repository.this[0]
}

moved {
  from = aws_iam_role.app
  to   = module.scaffold.aws_iam_role.app
}

moved {
  from = aws_eks_pod_identity_association.app[0]
  to   = module.scaffold.aws_eks_pod_identity_association.app[0]
}

moved {
  from = aws_iam_role.deployer
  to   = module.scaffold.aws_iam_role.deployer
}

moved {
  from = aws_iam_role_policy.deployer
  to   = module.scaffold.aws_iam_role_policy.deployer
}

moved {
  from = aws_eks_access_entry.deployer
  to   = module.scaffold.aws_eks_access_entry.deployer
}

moved {
  from = aws_eks_access_policy_association.deployer_edit
  to   = module.scaffold.aws_eks_access_policy_association.deployer_edit
}

moved {
  from = aws_iam_role.image_pusher[0]
  to   = module.scaffold.aws_iam_role.image_pusher[0]
}

moved {
  from = aws_iam_role_policy.image_pusher[0]
  to   = module.scaffold.aws_iam_role_policy.image_pusher[0]
}

moved {
  from = aws_iam_role.log_reader
  to   = module.scaffold.aws_iam_role.log_reader
}

moved {
  from = aws_iam_role_policy.log_reader
  to   = module.scaffold.aws_iam_role_policy.log_reader
}

moved {
  from = aws_eks_access_entry.log_reader
  to   = module.scaffold.aws_eks_access_entry.log_reader
}

moved {
  from = aws_eks_access_policy_association.log_reader_view
  to   = module.scaffold.aws_eks_access_policy_association.log_reader_view
}
