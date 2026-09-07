###########################################
# PC-IAC-002 — Variables del sample/
###########################################

variable "client" {
  description = "Nombre del cliente (max 10 chars, solo [a-z0-9-])."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.client)) && length(var.client) > 0 && length(var.client) <= 10
    error_message = "El valor de 'client' debe ser [a-z0-9-], max 10 chars."
  }
}

variable "project" {
  description = "Nombre del proyecto (max 15 chars, solo [a-z0-9-])."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project)) && length(var.project) > 0 && length(var.project) <= 15
    error_message = "El valor de 'project' debe ser [a-z0-9-], max 15 chars."
  }
}

variable "environment" {
  description = "Entorno: dev, qa, pdn, poc."
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn", "poc"], var.environment)
    error_message = "El valor de 'environment' debe ser: dev, qa, pdn, poc."
  }
}

variable "region" {
  description = "Región AWS."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil AWS CLI."
  type        = string
  default     = "default"
}

variable "nodegroups" {
  description = "Configuración base de los Node Groups. IDs vacíos se inyectan desde locals.tf."
  type = map(object({
    cluster_name         = optional(string, "")
    node_role_arn        = optional(string, "")
    subnet_ids           = optional(list(string), [])
    kubernetes_version   = optional(string, null)
    release_version      = optional(string, null)
    force_update_version = optional(bool, false)
    instance_types       = optional(list(string), ["t3.medium"])
    capacity_type        = optional(string, "ON_DEMAND")
    disk_size            = optional(number, 20)
    ami_type             = optional(string, "AL2023_x86_64_STANDARD")
    desired_size         = optional(number, 2)
    min_size             = optional(number, 2)
    max_size             = optional(number, 4)
    update_config = optional(object({
      max_unavailable            = optional(number, 1)
      max_unavailable_percentage = optional(number, null)
      update_strategy            = optional(string, "DEFAULT")
    }), null)
    node_repair_config = optional(object({
      enabled = optional(bool, true)
    }), null)
    launch_template = optional(object({
      id      = optional(string, null)
      name    = optional(string, null)
      version = string
    }), null)
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, "")
      effect = string
    })), [])
    timeouts = optional(object({
      create = optional(number, 60)
      update = optional(number, 60)
      delete = optional(number, 60)
    }), null)
    additional_tags = optional(map(string), {})
  }))
  default = {}
}
