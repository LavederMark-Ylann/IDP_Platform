// NAT Gateway (single, in first public subnet) for private subnet egress
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_settings.name}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = [for s in aws_subnet.subnets : s.id if s.map_public_ip_on_launch][0]

  tags = {
    Name = "${var.vpc_settings.name}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}