variable "vpc_settings" {
  description = "Parameters for VPC"
  type = object({
    name   = string
    region = string
    // Note : Avoid overlapping with private cloud cidr block
    cidr_block = string
  })
}

variable "subnets" {
  description = "Parameters for subnets"
  type = map(object({
    cidr_block              = string
    map_public_ip_on_launch = bool
    })
  )
}