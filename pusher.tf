// This role allows the Nullstone agent to push container images to ECR

resource "aws_iam_role" "image_pusher" {
  name               = "image-pusher-${local.resource_name}"
  tags               = local.tags
  assume_role_policy = data.aws_iam_policy_document.image_pusher_assume.json

  count = var.image_url == "" ? 1 : 0
}

data "aws_iam_policy_document" "image_pusher_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [local.ns_agent_user_arn]
    }
  }
}

resource "aws_iam_role_policy" "image_pusher" {
  role   = aws_iam_role.image_pusher[count.index].id
  policy = data.aws_iam_policy_document.image_pusher.json

  count = var.image_url == "" ? 1 : 0
}

data "aws_iam_policy_document" "image_pusher" {
  statement {
    sid    = "AllowPushPull"
    effect = "Allow"

    // The actions listed are necessary to perform actions to push ECR images
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:ListImages",
    ]

    resources = aws_ecr_repository.this.*.arn
  }

  statement {
    sid       = "AllowAuthorization"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}
