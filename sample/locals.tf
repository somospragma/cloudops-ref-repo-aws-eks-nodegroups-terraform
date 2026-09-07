###########################################
# PC-IAC-009 — Inyección de IDs dinámicos
# PC-IAC-026 — Patrón: tfvars → data → locals → main
###########################################

locals {
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # Inyecta cluster_name, node_role_arn y subnet_ids desde data sources
  nodegroups_transformed = {
    for key, config in var.nodegroups : key => merge(config, {
      cluster_name  = length(config.cluster_name) > 0 ? config.cluster_name : data.aws_eks_cluster.selected.name
      node_role_arn = length(config.node_role_arn) > 0 ? config.node_role_arn : data.aws_iam_role.node_role.arn
      subnet_ids    = length(config.subnet_ids) > 0 ? config.subnet_ids : tolist(data.aws_subnets.private.ids)
    })
  }
}
