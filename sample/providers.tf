###########################################
# PC-IAC-004 — default_tags transversales
# PC-IAC-005 — alias "principal" en el Root
# PC-IAC-006 — backend con encrypt = true
###########################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75.0"
    }
  }

  # Descomentar y configurar antes de ejecutar en un entorno real:
  # backend "s3" {
  #   bucket       = "pragma-eks-platform-dev-tfstate"
  #   key          = "eks-nodegroups/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

provider "aws" {
  region  = var.region
  alias   = "principal"
  profile = var.aws_profile

  default_tags {
    tags = {
      Client      = var.client
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "cloudops-ref-repo-aws-eks-nodegroups-terraform"
    }
  }
}
