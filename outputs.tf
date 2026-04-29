output "region" {
  value       = local.region
  description = "string ||| The region where the ECS container resides."
}

output "service_name" {
  value       = local.app_name
  description = "string ||| The name of the kubernetes deployment for the app."
}

output "service_namespace" {
  value       = local.app_namespace
  description = "string ||| The kubernetes namespace where the app resides."
}

output "log_provider" {
  value       = "eks"
  description = "string ||| 'eks'"
}

output "log_reader" {
  value       = module.scaffold.log_reader
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to view logs."
}

output "metrics_provider" {
  value       = "cloudwatch"
  description = "string ||| "
}

output "metrics_reader" {
  value       = module.scaffold.metrics_reader
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to view metrics."
}

output "metrics_mappings" {
  value = local.metrics_mappings
}

output "image_repo_url" {
  value       = module.scaffold.repository_url
  description = "string ||| Service container image url."
}

output "image_pusher" {
  value       = module.scaffold.image_pusher
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to push images."
}

output "deployer" {
  value       = module.scaffold.deployer
  description = "object({ role_arn: string, session_duration: number }) ||| An AWS Role with explicit privilege to deploy."
}

output "main_container_name" {
  value       = local.main_container_name
  description = "string ||| The name of the container definition for the main service container"
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
