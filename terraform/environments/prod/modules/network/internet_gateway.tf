// Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.vpc_settings.name}-internet-gateway"
  }
}
