// VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_settings.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_settings.name
  }
}