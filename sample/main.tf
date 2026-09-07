###########################################
# PC-IAC-026 — sample/main.tf SOLO invoca el módulo
#              NO contiene bloques locals{}
#              Consume local.nodegroups_transformed
###########################################

module "eks_nodegroup" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-eks-nodegroups-terraform.git?ref=feature/init-module-eks-nodegroup"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment

  nodegroups = local.nodegroups_transformed
}
