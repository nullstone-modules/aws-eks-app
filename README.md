# EKS App

This app module is used to create a long-running service such as an API, Web App, or Background Worker (always on).
To create a task/job that runs on a schedule or trigger, use EKS Task.

## When to use

EKS App is a great choice for APIs, Web Apps, or Background Workers (always on) and you want to run on AWS EKS (Kubernetes).

## Features

This module automatically configures the application with:
- [ ] Env Variables w/Handlebar interpolation
- [ ] Secrets Injection from AWS Secrets Manager via env vars
- [ ] EKS Pod Identity - an AWS IAM Role with permissions attachable via capabilities
- [ ] AWS Security Groups (capabilities can enable network traffic)
- [ ] ECR Repository following compliance (e.g. image tag immutability)
- [ ] Attachable Ingress devices (AWS Managed and Kubernetes-specific)
