terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {} // Get current session
data "aws_partition" "current" {}       // Get current partition (Standard/China/Gov)

resource "aws_iam_role" "terraform_networkrole" {
  name = "${var.project_name}-TerraformNetworkRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = data.aws_caller_identity.current.arn
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

// https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "terraform_networkpolicy" {
  name = "${var.project_name}-NetworkPolicy"
  role = aws_iam_role.terraform_networkrole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        // Overall privileges
        "ec2:CreateTags",
        // VPC privileges
        "ec2:CreateVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:DescribeVpcAttribute",
        "ec2:DeleteVpc",
        // Subnet privileges
        "ec2:CreateSubnet",
        "ec2:DescribeSubnets",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeNetworkInterfaces",
        // Internet Gateway privileges
        "ec2:CreateInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:DeleteInternetGateway",
        // Routes privileges
        "ec2:CreateRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DescribeRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        // Security groups
        "ec2:CreateSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:DeleteSecurityGroup",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:DescribeSecurityGroupRules"
      ]
      // To harden
      Resource = "*"
    }]
  })
}