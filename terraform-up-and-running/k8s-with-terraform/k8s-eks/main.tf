terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

provider "kubernetes" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks_cluster.cluster_certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

module "eks_cluster" {
  source       = "../modules/eks-cluster"
  name         = var.cluster_name
  min_size     = 1
  max_size     = 2
  desired_size = 1

  instance_types = ["t3.small"]
}

module "simple_webapp" {
  source = "../modules/k8s-app"

  name           = var.app_name
  image          = "training/webapp"
  replicas       = 2
  container_port = 5000

  environment_variables = {
    PROVIDER = "marcelo"
  }

  # Only deploy the app after the cluster has been deployed
  depends_on = [module.eks_cluster]
}