
// Public routes
resource "aws_route_table" "public_routing_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "public-${var.vpc_settings.name}-routing-table"
  }
}

resource "aws_route_table_association" "public_rta" {
  for_each = {
    for key, subnet in aws_subnet.subnets : key => subnet
    if subnet.map_public_ip_on_launch
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_routing_table.id
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.public_routing_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

// Private Routes

resource "aws_route_table" "private_routing_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "private-${var.vpc_settings.name}-routing-table"
  }
}

resource "aws_route_table_association" "private_rta" {
  for_each = {
    for key, subnet in aws_subnet.subnets : key => subnet
    if !subnet.map_public_ip_on_launch
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_routing_table.id
}