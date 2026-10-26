data "aws_availability_zones" "available" {
  state = "available"
}

// Subnets
resource "aws_subnet" "subnets" {
  for_each = {
    for index, key in keys(var.subnets) :
    var.subnets[key].cidr_block => {
      index                   = index
      cidr_block              = var.subnets[key].cidr_block
      map_public_ip_on_launch = var.subnets[key].map_public_ip_on_launch
    }
  }

  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.map_public_ip_on_launch
  // avoid putting everything inside a single availability zone
  availability_zone = data.aws_availability_zones.available.names[
    each.value.index % length(data.aws_availability_zones.available.names)
  ] // 4 / 3 : 0, 1, 2, 0

  tags = {
    Name = "${var.vpc_settings.name}-${each.value.map_public_ip_on_launch ? "public" : "private"}-${each.value.cidr_block}"
    CIDR = "${each.value.cidr_block}"
  }
}