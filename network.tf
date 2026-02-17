data "ns_connection" "network" {
  name     = "network"
  contract = "network/aws/vpc"
  via      = "${data.ns_connection.cluster_namespace.name}/${data.ns_connection.cluster.name}"
}

locals {
  vpc_id             = data.ns_connection.network.outputs.vpc_id
  private_cidrs      = data.ns_connection.network.outputs.private_cidrs
  public_cidrs       = data.ns_connection.network.outputs.public_cidrs
  private_subnet_ids = data.ns_connection.network.outputs.private_subnet_ids
}
