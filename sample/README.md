# Sample — Node Group del Sistema

Ejemplo del módulo `cloudops-ref-repo-aws-eks-nodegroups-terraform` para el Node Group de sistema en arquitectura híbrida.

## Patrón PC-IAC-026

```
terraform.tfvars → variables.tf → data.tf → locals.tf → main.tf
```

## Pre-requisitos

| Recurso | Nombre esperado |
|---|---|
| EKS Cluster | `{client}-{project}-{env}-eks-main` |
| Subnets | `{client}-{project}-{env}-subnet-service-*` |
| IAM Role nodos | `{client}-{project}-{env}-ng-role` |

## Ejecución

```bash
terraform init
terraform plan
terraform apply
```
