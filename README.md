# cloudops-ref-repo-aws-eks-nodegroups-terraform

Módulo de Referencia Terraform para la creación de **EKS Managed Node Groups** siguiendo las 26 reglas de gobernanza PC-IAC de Pragma y las mejores prácticas del AWS Well-Architected Framework.

---

## Descripción

Este módulo tiene **responsabilidad única** (PC-IAC-023): crea y gestiona exclusivamente Managed Node Groups de EKS.

| Recurso | Descripción |
|---|---|
| `aws_eks_node_group` | Node Group gestionado por AWS con Auto Scaling |

**No crea:** IAM Roles, Security Groups, VPC, Subnets, EKS Cluster, Addons. Esos recursos son responsabilidad de los módulos correspondientes o del Root IaC.

---

## Rol en la Arquitectura Híbrida

Este módulo implementa la **Capa 1** de la arquitectura híbrida recomendada por Pragma:

```
Capa 1 — Managed Node Group (este módulo)
  Nodos fijos On-Demand — sistema y plataforma
  CoreDNS, metrics-server, Argo CD, cert-manager, etc.
  Pods con affinity: karpenter.sh/nodepool DoesNotExist

Capa 2 — Auto Mode Karpenter (NodePool custom)
  Nodos dinámicos — workloads de aplicaciones
  Escala a 0 cuando no hay carga
```

El mecanismo de aislamiento es la affinity `karpenter.sh/nodepool: DoesNotExist` en los pods del sistema — los nodos del Node Group nunca tienen esa label, por lo que los pods del sistema siempre van al Node Group.

---

## Uso

```hcl
module "eks_nodegroup" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-eks-nodegroups-terraform.git?ref=feature/init-module-eks-nodegroup"

  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "eks-platform"
  environment = "dev"

  nodegroups = {
    "system" = {
      cluster_name  = module.eks_cluster.cluster_names["main"]
      node_role_arn = "arn:aws:iam::123456789012:role/pragma-eks-platform-dev-ng-role"
      subnet_ids    = ["subnet-aaa111", "subnet-bbb222"]

      kubernetes_version = "1.36"
      ami_type           = "AL2023_x86_64_STANDARD"
      instance_types     = ["t3.medium"]
      capacity_type      = "ON_DEMAND"

      desired_size = 2
      min_size     = 2
      max_size     = 4

      # Reparación automática de nodos enfermos
      node_repair_config = {
        enabled = true
      }

      # Update controlado — 1 nodo a la vez
      update_config = {
        max_unavailable = 1
        update_strategy = "DEFAULT"
      }

      additional_tags = {
        "role" = "system"
      }
    }
  }
}
```

---

## Inputs

| Variable | Tipo | Requerido | Default | Descripción |
|---|---|---|---|---|
| `client` | `string` | Sí | — | Nombre del cliente (max 10 chars) |
| `project` | `string` | Sí | — | Nombre del proyecto (max 15 chars) |
| `environment` | `string` | Sí | — | Entorno: `dev`, `qa`, `pdn`, `poc` |
| `nodegroups` | `map(object)` | Sí | — | Mapa de configuraciones de Node Groups |

### nodegroups — Campos principales

| Campo | Tipo | Default | Descripción |
|---|---|---|---|
| `cluster_name` | `string` | — | Nombre del cluster EKS |
| `node_role_arn` | `string` | — | ARN del IAM Role de los nodos |
| `subnet_ids` | `list(string)` | — | Mínimo 2 subnets en AZs distintas |
| `kubernetes_version` | `string` | `null` (hereda cluster) | Versión K8s del Node Group |
| `release_version` | `string` | `null` (última AMI) | Versión de la AMI |
| `force_update_version` | `bool` | `false` | Fuerza update si PDB bloquea |
| `instance_types` | `list(string)` | `["t3.medium"]` | Tipos de instancia |
| `capacity_type` | `string` | `"ON_DEMAND"` | `ON_DEMAND` o `SPOT` |
| `disk_size` | `number` | `20` | GB de disco (ignorado con launch_template) |
| `ami_type` | `string` | `"AL2023_x86_64_STANDARD"` | Tipo de AMI |
| `desired_size` | `number` | `2` | Nodos deseados (ignore_changes habilitado) |
| `min_size` | `number` | `1` | Mínimo de nodos |
| `max_size` | `number` | `4` | Máximo de nodos |
| `update_config` | `object` | `null` | Config de actualización |
| `node_repair_config.enabled` | `bool` | `true` | Reparación automática de nodos |
| `launch_template` | `object` | `null` | Launch Template custom |
| `labels` | `map(string)` | `{}` | Labels K8s en nodos |
| `taints` | `list(object)` | `[]` | Taints K8s en nodos |
| `additional_tags` | `map(string)` | `{}` | Tags adicionales |

---

## Outputs

| Output | Descripción |
|---|---|
| `nodegroup_names` | Mapa de nombres de los Node Groups |
| `nodegroup_arns` | Mapa de ARNs de los Node Groups |
| `nodegroup_ids` | Mapa de IDs (cluster:nodegroup) |
| `nodegroup_statuses` | Mapa de estados (ACTIVE, CREATING, etc.) |
| `autoscaling_group_names` | Lista de nombres de los ASGs asociados |
| `nodegroup_resources` | Mapa con ASGs y remote access SG por Node Group |

---

## Versiones Requeridas

| Componente | Versión Mínima |
|---|---|
| Terraform | `>= 1.5.0` |
| AWS Provider | `>= 5.75.0` |

---

## Nomenclatura

```
{client}-{project}-{environment}-ng-{key}

Ejemplo: pragma-eks-platform-dev-ng-system
```

---

## Cumplimiento PC-IAC

| Regla | ID | Implementación |
|---|---|---|
| Estructura de módulo | PC-IAC-001 | 10 archivos raíz + directorio sample/ |
| Variables tipadas y validadas | PC-IAC-002 | `map(object)` con `optional()` y validaciones |
| Nomenclatura estándar | PC-IAC-003 | `{client}-{project}-{env}-ng-{key}` en `locals.tf` |
| Etiquetas | PC-IAC-004 | `merge(Name, additional_tags)` en recursos |
| Provider alias | PC-IAC-005 | `provider = aws.project` |
| Versiones fijadas | PC-IAC-006 | `versions.tf` con `configuration_aliases` |
| Outputs granulares | PC-IAC-007 | Solo IDs/ARNs/nombres |
| Hardenizado seguridad | PC-IAC-020 | `node_repair_config`, `lifecycle ignore_changes` |
| Responsabilidad única | PC-IAC-023 | Solo Node Groups, sin IAM/SG/VPC |

---

## Decisiones de Diseño

### lifecycle ignore_changes en desired_size
El `desired_size` tiene `ignore_changes` para que el Cluster Autoscaler o ajustes manuales puedan cambiar el número de nodos sin que el próximo `terraform apply` lo revierta. El control del escalado queda en manos del autoscaler, no de Terraform.

### node_repair_config
La reparación automática de nodos requiere que el addon `eks-node-monitoring-agent` esté instalado en el cluster. Sin ese addon, la feature no opera aunque esté habilitada en el Node Group.

### AL2023 como AMI por defecto
`AL2023_x86_64_STANDARD` es el sucesor de AL2 y es la AMI recomendada por AWS para nuevos Node Groups. Incluye mejor soporte de seguridad y es la que AWS continuará manteniendo.
