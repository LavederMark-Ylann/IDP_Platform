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
  }
}

provider "aws" {
  region = module.settings.aws_regions.sydney
  assume_role {
    role_arn = "arn:aws:iam::646468991444:role/IDP_Platform-TerraformNetworkRole"
  }
}