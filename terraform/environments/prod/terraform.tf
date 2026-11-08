terraform {
  backend "s3" {
    bucket = "idp-platform-project-remote-tf-state"
    key    = "prod/terraform.tfstate"
    region = "ap-southeast-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region = module.settings.aws_regions.sydney
  assume_role {
    role_arn = "arn:aws:iam::646468991444:role/IDP_Platform-TerraformNetworkRole"
  }
}

data "aws_eks_cluster" "cluster" {
  name = "idp-platform-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "idp-platform-eks"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}