data "aws_region" "this" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "this" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.this.region
  partition  = data.aws_partition.this.partition
}
