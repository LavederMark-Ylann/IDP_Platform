module "settings" {
  source = "./modules/settings"
}

module "network" {
  source = "./modules/network"
  vpc_settings = {
    name       = "Kubernetes"
    region     = module.settings.aws_regions.sydney
    cidr_block = "10.0.0.0/16"
  }
  subnets = {
    // public
    public1 = {
      cidr_block              = "10.0.1.0/24"
      map_public_ip_on_launch = true
    },
    public2 = {
      cidr_block              = "10.0.2.0/24"
      map_public_ip_on_launch = true
    },
    // private
    private11 = {
      cidr_block              = "10.0.11.0/24"
      map_public_ip_on_launch = false
    },
    private12 = {
      cidr_block              = "10.0.12.0/24"
      map_public_ip_on_launch = false
    }
  }
}

module "security" {
  source = "./modules/security"

  vpc_id = module.network.vpc_id
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "idp-platform-eks"
  vpc_id       = module.network.vpc_id
  # Free-tier / no-NAT: run nodes in public subnets
  subnet_ids   = module.network.public_subnets_id
}

module "finops" {
  source = "./modules/finops"

  monthly_limit_usd = 50
  alert_email       = "" # set your email to receive alerts
  project_tag       = "IDP_Platform"
}

module "argocd" {
  source = "./modules/argocd"

  cluster_name = "idp-platform-eks"
  depends_on   = [module.eks]
}