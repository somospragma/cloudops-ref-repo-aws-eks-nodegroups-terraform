###########################################
# PC-IAC-007 — Outputs granulares (solo IDs/ARNs, no objetos completos)
# PC-IAC-014 — Splat expressions con values()[*]
###########################################

# ── Identificadores ───────────────────────────────────────────────────────

output "nodegroup_names" {
  description = "Mapa de nombres de los Node Groups. Clave = key del mapa nodegroups."
  value = {
    for k, v in var.nodegroups : k => local.nodegroup_names[k].name
  }
}

output "nodegroup_arns" {
  description = "Mapa de ARNs de los Node Groups de EKS."
  value = {
    for k, v in aws_eks_node_group.this : k => v.arn
  }
}

output "nodegroup_ids" {
  description = "Mapa de IDs de los Node Groups (formato: cluster_name:nodegroup_name)."
  value = {
    for k, v in aws_eks_node_group.this : k => v.id
  }
}

# ── Estado ────────────────────────────────────────────────────────────────

output "nodegroup_statuses" {
  description = "Mapa de estados de los Node Groups (CREATING, ACTIVE, UPDATING, DELETING, etc.)."
  value = {
    for k, v in aws_eks_node_group.this : k => v.status
  }
}

# ── Auto Scaling ──────────────────────────────────────────────────────────

output "autoscaling_group_names" {
  description = "Lista de nombres de los Auto Scaling Groups asociados a los Node Groups."
  value = flatten([
    for ng in aws_eks_node_group.this : [
      for asg in ng.resources[0].autoscaling_groups : asg.name
    ]
  ])
}

# ── Recursos del Node Group ───────────────────────────────────────────────

output "nodegroup_resources" {
  description = "Mapa de recursos de cada Node Group (ASGs y remote access SG si aplica)."
  value = {
    for k, v in aws_eks_node_group.this : k => {
      autoscaling_groups              = [for asg in v.resources[0].autoscaling_groups : asg.name]
      remote_access_security_group_id = v.resources[0].remote_access_security_group_id
    }
  }
}
