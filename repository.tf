locals {
  // If someone specifies `var.image_url`, the ecr repository will not be created
  // The following variable sets up the effective docker image
  image_url = try(aws_ecr_repository.this[0].repository_url, var.image_url)
}

// This is a bit odd - we're creating a repository for every environment
// We need to find a better way to do this
resource "aws_ecr_repository" "this" {
  count = var.image_url == "" ? 1 : 0

  name                 = local.resource_name
  tags                 = local.tags
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.this.arn
  }
}
