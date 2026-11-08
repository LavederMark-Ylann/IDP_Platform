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
        "ec2:DescribeSecurityGroupRules",
        // NAT Gateway
        "ec2:CreateNatGateway",
        // EKS
        "eks:CreateCluster",
        "eks:DescribeCluster",
        "eks:DeleteCluster",
        "eks:CreateNodegroup",
        "eks:DescribeNodegroup",
        "eks:DeleteNodegroup",
        "eks:TagResource",
        "eks:CreateAddon",
        "eks:DescribeAddon",
        "eks:DeleteAddon",
        // EKS Role
        "iam:CreateRole",
        "iam:GetRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:ListInstanceProfilesForRole",
        "iam:CreateServiceLinkedRole",
        "ec2:ReleaseAddress",
        // EC2
        "ec2:DescribeAddresses",
        "ec2:DescribeAddressesAttribute",
        "ec2:AllocateAddress",
        // FinOps
        "budgets:CreateBudget",
        "budgets:DescribeBudgets",
        "budgets:ModifyBudget",
        "budgets:DeleteBudget",
        "ce:CreateAnomalyMonitor",
        "ce:GetAnomalyMonitors",
        "ce:DeleteAnomalyMonitor",
        "ce:CreateAnomalySubscription",
        "ce:GetAnomalySubscriptions",
        "ce:DeleteAnomalySubscription"
      ]
      // To harden
      Resource = "*"
    }]
  })
}