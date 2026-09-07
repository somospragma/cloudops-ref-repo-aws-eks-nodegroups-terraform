###########################################
# PC-IAC-010 — for_each en todos los recursos
# PC-IAC-014 — Bloques dynamic para configuración opcional
# PC-IAC-020 — Hardenizado: node_repair_config, lifecycle protect
# PC-IAC-023 — Responsabilidad única: solo Node Groups EKS
###########################################

resource "aws_eks_node_group" "this" {
  provider = aws.project
  for_each = var.nodegroups

  cluster_name    = each.value.cluster_name
  node_group_name = local.nodegroup_names[each.key].name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids

  # ── Versión de Kubernetes ─────────────────────────────────────────────────
  version              = each.value.kubernetes_version
  release_version      = each.value.release_version
  force_update_version = each.value.force_update_version

  # ── Configuración de instancias ───────────────────────────────────────────
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.launch_template != null ? null : each.value.disk_size
  ami_type       = each.value.launch_template != null ? null : each.value.ami_type

  # ── Escalado ──────────────────────────────────────────────────────────────
  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  # ── Configuración de actualización ────────────────────────────────────────
  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []
    content {
      max_unavailable            = update_config.value.max_unavailable
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
      update_strategy            = update_config.value.update_strategy
    }
  }

  # ── Reparación automática de nodos (PC-IAC-020) ───────────────────────────
  # Habilitar para Node Groups que corren workloads críticos (sistema/plataforma)
  dynamic "node_repair_config" {
    for_each = each.value.node_repair_config != null ? [each.value.node_repair_config] : []
    content {
      enabled = node_repair_config.value.enabled
    }
  }

  # ── Launch Template (opcional) ────────────────────────────────────────────
  # Usar cuando se necesita configuración avanzada de EC2 (user data, SGs extra, etc.)
  # Conflicta con disk_size, ami_type y remote_access
  dynamic "launch_template" {
    for_each = each.value.launch_template != null ? [each.value.launch_template] : []
    content {
      id      = launch_template.value.id
      name    = launch_template.value.name
      version = launch_template.value.version
    }
  }

  # ── Taints de Kubernetes ───────────────────────────────────────────────────
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # ── Labels de Kubernetes ──────────────────────────────────────────────────
  labels = each.value.labels

  # ── Timeouts ──────────────────────────────────────────────────────────────
  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = "${timeouts.value.create}m"
      update = "${timeouts.value.update}m"
      delete = "${timeouts.value.delete}m"
    }
  }

  # ── Lifecycle ─────────────────────────────────────────────────────────────
  # ignore_changes en desired_size: permite que el Cluster Autoscaler o
  # ajustes manuales cambien el tamaño sin que Terraform lo revierta
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  # PC-IAC-004: Name explícito + merge con additional_tags
  tags = merge(
    { Name = local.nodegroup_names[each.key].name },
    each.value.additional_tags
  )
}
