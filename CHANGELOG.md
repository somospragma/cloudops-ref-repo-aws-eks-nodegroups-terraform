# Changelog

Todos los cambios notables de este módulo se documentan en este archivo.

El formato sigue [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- `versions.tf` separado con `configuration_aliases = [aws.project]` (PC-IAC-005/006)
- `data.tf` con comentario PC-IAC-011
- Variable `kubernetes_version` — control explícito de la versión K8s del Node Group
- Variable `force_update_version` — fuerza update si PDB bloquea el drain
- Variable `node_repair_config` — reparación automática de nodos enfermos (PC-IAC-020)
- Variable `launch_template` — soporte para Launch Template custom
- Variable `update_config.update_strategy` — DEFAULT o MINIMAL
- Variable `ami_type` actualizada con AL2023_x86_64_STANDARD como default
- `lifecycle { ignore_changes = [scaling_config[0].desired_size] }` — compatible con Cluster Autoscaler
- Tags con `merge(Name, additional_tags)` en todos los recursos (PC-IAC-004)
- Output `nodegroup_resources` (ASGs + remote access SG)
- Validaciones: min_size <= desired_size <= max_size, subnets >= 2, update_config mutuamente exclusivo, launch_template id o name
- `environment` ahora acepta `poc` además de dev/qa/pdn
- Directorio `sample/` con patrón PC-IAC-026
- `CHANGELOG.md`
- `README.md` completo

### Changed
- `providers.tf` ahora es solo documentación (sin bloque terraform)
- `locals.tf` agrega `governance_prefix`
- `outputs.tf` agrega outputs granulares adicionales

### Fixed
- Tags en `aws_eks_node_group` ahora incluyen `Name` explícito (PC-IAC-004)
- `providers.tf` separado de `versions.tf` correctamente

---

## [1.0.0] - TBD

### Added
- Versión inicial estable del módulo
