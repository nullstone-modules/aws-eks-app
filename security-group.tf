resource "aws_security_group" "this" {
  name        = local.resource_name
  vpc_id      = local.vpc_id
  tags        = merge(local.tags, { Name = local.resource_name })
  description = "Managed by Terraform"
}

resource "aws_security_group_rule" "this-dns-tcp-to-world" {
  description       = "Allow service to communicate with any nameserver over TCP"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this-dns-udp-to-world" {
  description       = "Allow service to communicate with any nameserver over UDP"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "udp"
  from_port         = 53
  to_port           = 53
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this-https-to-world" {
  description       = "Allow service to communicate with any server over HTTPS"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "this-http-from-private-subnets" {
  description       = "Allow any service on this network in private subnets to communicate with this service on the service port"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.service_port
  to_port           = var.service_port
  cidr_blocks       = local.private_cidrs

  count = var.service_port == 0 ? 0 : signum(length(local.private_cidrs))
}

// TODO: Drop this once we have a better way of reaching via bastion
resource "aws_security_group_rule" "this-http-from-public-subnets" {
  description       = "Allow any service on this network in public subnets to communicate with this service on the service port"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.service_port
  to_port           = var.service_port
  cidr_blocks       = local.public_cidrs

  count = var.service_port == 0 ? 0 : signum(length(local.public_cidrs))
}

resource "aws_security_group_rule" "this-http-to-private-subnets" {
  description       = "Allow this service to communicate with other services on the network over HTTP"
  security_group_id = aws_security_group.this.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = local.private_cidrs

  count = signum(length(local.private_cidrs))
}
