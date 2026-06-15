# Terraform Infrastructure

This folder contains the infrastructure code for deploying Sparkle Note on AWS with Terraform.

The main stack lives in [`terraform/infra`](/home/mj/Sparkle-Note/terraform/infra) and provisions networking, EKS, IAM, ECR, IRSA roles, and a Secrets Manager secret.

## Folder Layout

```text
terraform/
├── README.md
└── infra/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── provider.tf
    ├── versions.tf
    ├── terraform.tfvars
    ├── CHANGES.md
    └── modules/
        ├── vpc/
        ├── iam/
        ├── eks_cluster/
        ├── eks_node_group/
        ├── ecr/
        ├── irsa/
        └── secrets-manager/
```

## What This Stack Creates

- A VPC with public and private subnets
- An EKS cluster
- An EKS managed node group
- IAM roles for the EKS control plane and worker nodes
- IRSA roles for components like AWS Load Balancer Controller and External Secrets
- ECR repositories for application images
- An AWS Secrets Manager secret

## Modules

### `vpc`

Creates the base networking layer used by the cluster.

### `iam`

Creates IAM roles needed by the EKS control plane and worker nodes.

### `eks_cluster`

Creates the EKS cluster and related OIDC provider outputs used for IRSA.

### `eks_node_group`

Creates the managed worker node group for the cluster.

### `irsa`

Creates IAM roles for Kubernetes service accounts, including ALB and External Secrets integrations.

### `ecr`

Creates one or more ECR repositories from the `repositories` input list.

### `secrets-manager`

Creates an AWS Secrets Manager secret used by the platform.

## Inputs

The root stack currently expects these variables:

| Variable | Description | Example |
| --- | --- | --- |
| `cidr_block` | VPC CIDR block | `10.0.0.0/16` |
| `project_name` | Project prefix used in resource naming | `sparkle-note` |
| `cluster_name` | EKS cluster name | `sparkle-note-cluster` |
| `region` | AWS region | `ap-south-1` |
| `azs` | Availability zones for subnet placement | `["ap-south-1a", "ap-south-1b"]` |
| `repositories` | ECR repositories to create | `["sparkle-note-backend", "sparkle-note-frontend"]` |

Example values are already present in [infra/terraform.tfvars](/home/mj/Sparkle-Note/terraform/infra/terraform.tfvars).

## Outputs

After `terraform apply`, the stack exposes:

- EKS cluster name
- EKS cluster endpoint
- OIDC provider URL
- VPC ID
- Public and private subnet IDs
- ECR repository URLs
- IAM role ARNs

See [infra/outputs.tf](/home/mj/Sparkle-Note/terraform/infra/outputs.tf) for the full output list.

## Prerequisites

- Terraform `>= 1.5`
- AWS credentials configured locally
- An AWS account with permissions for VPC, EKS, IAM, ECR, and Secrets Manager

## Usage

From the infrastructure directory:

```bash
cd terraform/infra
terraform init
terraform plan
terraform apply
```

To destroy the stack:

```bash
terraform destroy
```

## Important Notes

- `provider.tf` uses the `region` variable to select the AWS region.
- `backend.tf` is currently empty, so the stack is using local state unless you add a remote backend.
- This repo currently includes local state files in `terraform/infra`, which means the stack may already have been applied from this workspace.
- The root module currently creates a placeholder secret value of `"your-sensitive-data"`. Replace that with a safer pattern before using this in a real environment.

## Recommended Next Steps

- Add a remote backend such as S3 + DynamoDB locking
- Move secret values out of Terraform source and into a secure delivery flow
- Review naming, tags, and environment separation if you plan to support dev/staging/prod stacks

## Additional Notes

Infrastructure change history and rationale are documented in [infra/CHANGES.md](/home/mj/Sparkle-Note/terraform/infra/CHANGES.md).
