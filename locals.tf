###########################################
# PC-IAC-003 — Nomenclatura estándar
# PC-IAC-009 — Lógica de transformación en locals
# PC-IAC-012 — Único bloque locals, estructuras reutilizables
###########################################

locals {

  # ── Prefijo de gobernanza base ────────────────────────────────────────────
  # PC-IAC-003: patrón {client}-{project}-{environment}
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # ── Nombres de Node Groups ────────────────────────────────────────────────
  # PC-IAC-003: patrón {client}-{project}-{environment}-ng-{key}
  nodegroup_names = {
    for k, v in var.nodegroups : k => {
      name = "${local.governance_prefix}-ng-${k}"
    }
  }

}
