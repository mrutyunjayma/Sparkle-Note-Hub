output "cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.eks_cluster.cluster_endpoint
}

output "oidc_provider_url" {
  value = module.eks_cluster.oidc_provider_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "ecr_repo_urls" {
  value = module.ecr.repo_urls
}

output "iam_roles" {
  value = {
    cluster_role          = module.iam.cluster_role_arn
    node_role             = module.iam.node_role_arn
    external_secrets_role = module.irsa.external_secrets_role_arn
    alb_role              = module.irsa.alb_role_arn
  }
}