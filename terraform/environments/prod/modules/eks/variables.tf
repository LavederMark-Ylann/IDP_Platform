variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "idp-platform-eks"
}

// default as 1.36 to practice version upgrade of cluster on EKS
variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.36"
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster and node group (public subnets for free-tier/no-NAT setup)"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}