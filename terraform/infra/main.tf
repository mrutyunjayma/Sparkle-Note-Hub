module "vpc" {
  source = "./modules/vpc"

  cidr_block   = var.cidr_block
  project_name = var.project_name
  azs          = var.azs
  cluster_name = var.cluster_name
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

module "eks_cluster" {
  source = "./modules/eks_cluster"

  cluster_name     = var.cluster_name
  subnet_ids       = module.vpc.private_subnets
  cluster_role_arn = module.iam.cluster_role_arn
}

module "secrets" {
  source       = "./modules/secrets-manager"
  name         = "sparkle-note-secrets"
  secret_value = "your-sensitive-data"
}


module "eks_node_group" {
  source = "./modules/eks_node_group"

  cluster_name  = module.eks_cluster.cluster_name
  node_role_arn = module.iam.node_role_arn
  subnet_ids    = module.vpc.private_subnets

  depends_on = [module.eks_cluster,module.iam]
}

module "irsa" {
  source = "./modules/irsa"
  cluster_name = var.cluster_name
  oidc_provider_arn  = module.eks_cluster.oidc_provider_arn
  oidc_provider_url  = module.eks_cluster.oidc_provider_url
}

module "ecr" {
  source = "./modules/ecr"

  repositories = var.repositories
}