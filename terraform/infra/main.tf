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
  secret_value = jsonencode({
    MONGODB_URI     = "mongodb+srv://mrutyunjaymasanta03_db_user:mj-admin_sparkle-note@sparkle-note.4pqt3rc.mongodb.net/?appName=sparkle-note"
    MONGODB_DB_NAME = "sparkle-note"
    DATABASE_URL    = "mongodb+srv://mrutyunjaymasanta03_db_user:mj-admin_sparkle-note@sparkle-note.4pqt3rc.mongodb.net/?appName=sparkle-note"
  })
}


module "eks_node_group" {
  source = "./modules/eks_node_group"

  cluster_name  = module.eks_cluster.cluster_name
  node_role_arn = module.iam.node_role_arn
  subnet_ids    = module.vpc.private_subnets

  depends_on = [module.eks_cluster, module.iam]
}

module "eks_addons" {
  source = "./modules/eks_addons"

  cluster_name = module.eks_cluster.cluster_name

  depends_on = [module.eks_node_group]
}

module "irsa" {
  source            = "./modules/irsa"
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_provider_url = module.eks_cluster.oidc_provider_url
}

module "ecr" {
  source = "./modules/ecr"

  repositories = var.repositories
}
