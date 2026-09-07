###########################################
# PC-IAC-002 — Variables del Módulo
# PC-IAC-009 — Tipos explícitos + optional()
###########################################

# ── Variables de Gobernanza (Obligatorias) ────────────────────────────────

variable "client" {
  description = "Nombre del cliente o unidad de negocio. Usado para construir el nombre del recurso. Solo letras minúsculas, números y guiones."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client)) && length(var.client) > 0 && length(var.client) <= 10
    error_message = "El valor de 'client' debe contener solo letras minúsculas, números y guiones, max 10 caracteres."
  }
}

variable "project" {
  description = "Nombre del proyecto. Usado para construir el nombre del recurso. Solo letras minúsculas, números y guiones."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) > 0 && length(var.project) <= 15
    error_message = "El valor de 'project' debe contener solo letras minúsculas, números y guiones, max 15 caracteres."
  }
}

variable "environment" {
  description = "Entorno de despliegue. Valores permitidos: dev, qa, pdn, poc."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "pdn", "poc"], var.environment)
    error_message = "El valor de 'environment' debe ser uno de: dev, qa, pdn, poc."
  }
}

# ── Configuración de Node Groups ──────────────────────────────────────────

variable "nodegroups" {
  description = <<-EOT
    Mapa de configuraciones de Managed Node Groups de EKS.
    La clave del mapa se usa en el nombre: {client}-{project}-{env}-ng-{key}.

    Uso principal en arquitectura híbrida:
    - Node Group para pods del sistema y plataforma (CoreDNS, Argo CD, etc.)
    - Los pods se dirigen aquí via affinity: karpenter.sh/nodepool DoesNotExist
    - Karpenter gestiona los workloads de aplicaciones en NodePools separados
  EOT
  type = map(object({

    # ── Configuración básica ──────────────────────────────────────────────
    cluster_name  = string
    # Nombre del cluster EKS donde se crea el Node Group. REQUERIDO.

    node_role_arn = string
    # ARN del IAM Role de los nodos. Debe tener:
    # AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly

    subnet_ids    = list(string)
    # Subnets donde se crean los nodos. Mínimo 2 en AZs distintas para HA.
    # Usar subnets privadas (best practice).

    # ── Versión ───────────────────────────────────────────────────────────
    kubernetes_version   = optional(string, null)
    # Versión de Kubernetes. Si null, hereda la versión del cluster.
    # Especificar explícitamente para controlar upgrades.

    release_version      = optional(string, null)
    # Versión de la AMI. Si null, usa la última compatible con kubernetes_version.
    # Formato: "1.32.2-20260101" — controlar para reproducibilidad.

    force_update_version = optional(bool, false)
    # Fuerza el update si hay pods que no pueden drenarse por PDB.

    # ── Instancias ────────────────────────────────────────────────────────
    instance_types = optional(list(string), ["t3.medium"])
    # Tipos de instancia. Para Node Group del sistema: t3.medium es suficiente.
    # Lista de múltiples tipos = AWS elige el más disponible.

    capacity_type  = optional(string, "ON_DEMAND")
    # ON_DEMAND (default, recomendado para sistema) o SPOT.

    disk_size      = optional(number, 20)
    # Tamaño del disco en GB. Default: 20GB. Ignorado si launch_template != null.

    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    # Tipo de AMI. AL2023_x86_64_STANDARD es el recomendado para nuevos clusters.
    # Ignorado si launch_template != null.
    # Valores: AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD, AL2_x86_64,
    #          AL2_ARM_64, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64, etc.

    # ── Escalado ──────────────────────────────────────────────────────────
    desired_size = optional(number, 2)
    min_size     = optional(number, 1)
    max_size     = optional(number, 4)
    # desired_size tiene lifecycle ignore_changes — el Cluster Autoscaler
    # puede modificarlo sin que Terraform lo revierta.

    # ── Actualización ─────────────────────────────────────────────────────
    update_config = optional(object({
      max_unavailable            = optional(number, 1)
      # Nodos no disponibles simultáneamente durante updates. Default: 1.
      max_unavailable_percentage = optional(number, null)
      # Alternativa porcentual a max_unavailable. Mutuamente exclusivos.
      update_strategy            = optional(string, "DEFAULT")
      # DEFAULT o MINIMAL. MINIMAL minimiza disrupciones.
    }), null)

    # ── Reparación automática de nodos (PC-IAC-020) ───────────────────────
    node_repair_config = optional(object({
      enabled = optional(bool, true)
      # Habilita la reparación automática de nodos enfermos.
      # Recomendado: true para Node Groups de sistema y plataforma.
      # Requiere eks-node-monitoring-agent instalado en el cluster.
    }), null)

    # ── Launch Template (avanzado) ────────────────────────────────────────
    launch_template = optional(object({
      id      = optional(string, null)
      name    = optional(string, null)
      version = string
      # Usar cuando se necesita: user_data custom, SGs adicionales,
      # configuración de bloque de dispositivos, etc.
      # Conflicta con: disk_size, ami_type, remote_access.
    }), null)

    # ── Kubernetes ────────────────────────────────────────────────────────
    labels = optional(map(string), {})
    # Labels de Kubernetes en los nodos. Solo los gestionados por la API de EKS.

    taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
      # Efectos válidos: NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
    })), [])

    # ── Timeouts ──────────────────────────────────────────────────────────
    timeouts = optional(object({
      create = optional(number, 60) # Minutos. Default Terraform: 60m
      update = optional(number, 60)
      delete = optional(number, 60)
    }), null)

    # ── Tags ──────────────────────────────────────────────────────────────
    additional_tags = optional(map(string), {})
    # Tags adicionales. Se fusionan con la etiqueta Name (PC-IAC-004).
  }))

  # ── Validaciones ──────────────────────────────────────────────────────

  validation {
    condition     = length(var.nodegroups) > 0
    error_message = "Debe proporcionarse al menos una configuración de Node Group."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodegroups : contains(["ON_DEMAND", "SPOT"], v.capacity_type)
    ])
    error_message = "El valor de 'capacity_type' debe ser 'ON_DEMAND' o 'SPOT'."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodegroups : v.min_size <= v.desired_size && v.desired_size <= v.max_size
    ])
    error_message = "El tamaño debe cumplir: min_size <= desired_size <= max_size."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodegroups : length(v.subnet_ids) >= 2
    ])
    error_message = "Deben especificarse al menos 2 subnet_ids en zonas de disponibilidad diferentes."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodegroups : (
        v.update_config == null ? true : (
          v.update_config.max_unavailable == null || v.update_config.max_unavailable_percentage == null
        )
      )
    ])
    error_message = "max_unavailable y max_unavailable_percentage son mutuamente exclusivos en update_config."
  }

  validation {
    condition = alltrue([
      for k, v in var.nodegroups : (
        v.launch_template == null ? true : (
          v.launch_template.id != null || v.launch_template.name != null
        )
      )
    ])
    error_message = "launch_template requiere 'id' o 'name' (al menos uno)."
  }
}
