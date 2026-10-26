output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main_vpc.cidr_block
}

output "public_subnets_id" {
  description = "List of Public Subnets ID"
  value = [
    for subnet in aws_subnet.subnets : subnet.id
    if subnet.map_public_ip_on_launch
  ]
}

output "private_subnets_id" {
  description = "List of Private Subnets ID"
  value = [
    for subnet in aws_subnet.subnets : subnet.id
    if !subnet.map_public_ip_on_launch
  ]
}