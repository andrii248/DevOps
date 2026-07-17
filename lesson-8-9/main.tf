/*
module "s3_backend" {
  source              = "./modules/s3-backend"
  bucket_name         = "andy-lesson-7-tfstate"
  dynamodb_table_name = "terraform-locks"
  environment         = "dev"
}
*/

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "lesson-7-vpc"
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "lesson-7-ecr"
  scan_on_push = true
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = "lesson-7-eks"
  cluster_version    = "1.30"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
}
module "jenkins" {
  source = "./modules/jenkins"

  cluster_name       = module.eks.cluster_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
  ecr_repository_arn = module.ecr.repository_arn

  app_repository_url = var.app_repository_url
  github_owner       = var.github_owner
  github_token       = var.github_token

  depends_on = [
    module.eks
  ]
}

module "argocd" {
  source = "./modules/argocd"

  gitops_repository_url = "https://github.com/andrii248/django-app-gitops.git"
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.13.1"
  namespace  = "kube-system"

  create_namespace = false
  timeout          = 600
  wait             = true
  atomic           = true
  cleanup_on_fail  = true
}
