###########################################
# PC-IAC-007 — Outputs del sample
###########################################

output "nodegroup_names" {
  description = "Nombres de los Node Groups creados."
  value       = module.eks_nodegroup.nodegroup_names
}

output "nodegroup_arns" {
  description = "ARNs de los Node Groups creados."
  value       = module.eks_nodegroup.nodegroup_arns
}

output "nodegroup_statuses" {
  description = "Estados de los Node Groups."
  value       = module.eks_nodegroup.nodegroup_statuses
}

output "autoscaling_group_names" {
  description = "Nombres de los Auto Scaling Groups asociados."
  value       = module.eks_nodegroup.autoscaling_group_names
}
