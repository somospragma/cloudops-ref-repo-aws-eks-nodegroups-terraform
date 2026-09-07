###########################################
# PC-IAC-011 — Data Sources del Root/sample
# PC-IAC-026 — Inyectan IDs dinámicos en locals.tf
###########################################

# ── Cluster EKS existente ─────────────────────────────────────────────────
data "aws_eks_cluster" "selected" {
  name = "${var.client}-${var.project}-${var.environment}-eks-main"
}

# ── Subnets privadas ──────────────────────────────────────────────────────
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.selected.vpc_config[0].vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.client}-${var.project}-${var.environment}-subnet-service-*"]
  }
}

# ── IAM Role del Node Group ───────────────────────────────────────────────
data "aws_iam_role" "node_role" {
  name = "${var.client}-${var.project}-${var.environment}-ng-role"
}
