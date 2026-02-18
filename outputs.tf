output "region" {
  value       = local.region
  description = "string ||| The region where the ECS container resides."
}

output "log_provider" {
  value       = "eks"
  description = "string ||| 'eks'"
}

output "log_reader" {
  value = {
    role_arn         = aws_iam_role.log_reader.arn
    session_duration = 3600 // 1 hour
  }

  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to view logs."
}

output "metrics_provider" {
  value       = "cloudwatch"
  description = "string ||| "
}

/*
TODO: Configure metrics and create metrics_reader role
output "metrics_reader" {
  value = {
    role_arn         = aws_iam_role.metrics_reader.arn
    session_duration = 3600 // 1 hour
  }

  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to view metrics."
}
*/

output "metrics_mappings" {
  value = local.metrics_mappings
}

output "image_repo_url" {
  value       = local.image_url
  description = "string ||| Service container image url."
}

output "image_pusher" {
  value = {
    role_arn         = try(aws_iam_role.image_pusher[0].arn, "")
    session_duration = 900 // 15 minutes
  }

  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to push images."
}

output "deployer" {
  value = {
    role_arn         = aws_iam_role.deployer.arn
    session_duration = 3600 // 1 hour
  }

  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to deploy."
}

output "app_security_group_id" {
  value       = aws_security_group.this.id
  description = "string ||| The ID of the security group attached to the app."
}

output "private_urls" {
  value       = local.private_urls
  description = "list(string) ||| A list of URLs only accessible inside the network"
}

output "public_urls" {
  value       = local.public_urls
  description = "list(string) ||| A list of URLs accessible to the public"
}

output "private_hosts" {
  value       = local.private_hosts
  description = "list(string) ||| A list of Hostnames only accessible inside the network"
}

output "public_hosts" {
  value       = local.public_hosts
  description = "list(string) ||| A list of Hostnames accessible to the public"
}
