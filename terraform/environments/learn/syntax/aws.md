# AWS resources for this project

This guide maps the AWS building blocks used in this repository and the planned path toward an application running on EKS. Azure equivalents are the closest commonly used services; they are not always exact matches.

The examples are intentionally small learning snippets. They assume an AWS provider is configured and, where needed, that referenced resources (such as a VPC or IAM role) already exist. Replace example names, IDs, CIDRs, AMI IDs, and policies with values appropriate for your account and region. Review `terraform plan` before applying anything that can create billable resources.

## Networking

| Terraform resource | Purpose | Closest Azure equivalent |
|---|---|---|
| `aws_vpc` | Creates an isolated virtual network for AWS resources. | Virtual Network (`azurerm_virtual_network`) |
| `aws_subnet` | Creates an IP range inside a VPC, commonly public or private and spread across availability zones. | Subnet (`azurerm_subnet`) |
| `aws_internet_gateway` | Connects a VPC to the public internet when a route points to it. | No single direct resource; commonly an Azure Virtual Network Gateway or public IP/NAT design, depending on the use case. |
| `aws_route_table` | Holds routes that determine where subnet traffic is sent. | Route table (`azurerm_route_table`) |
| `aws_route` | Adds a destination and target to a route table. | Route (`azurerm_route`) |
| `aws_route_table_association` | Associates a route table with a subnet. | Subnet-to-route-table association (`azurerm_subnet_route_table_association`) |
| `aws_eip` | Allocates a stable public IPv4 address, often for a NAT Gateway. | Public IP (`azurerm_public_ip`) |
| `aws_nat_gateway` | Lets resources in private subnets initiate internet access without accepting unsolicited inbound connections. | NAT Gateway (`azurerm_nat_gateway`) |
| `aws_security_group` | Controls inbound and outbound traffic for supported resources such as EC2 and EKS interfaces. | Network Security Group (`azurerm_network_security_group`) |

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_security_group" "app" {
  name   = "app"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.0.0.0/16"]
  }
}
```

The NAT Gateway example only creates the gateway. To use it, create a route table for private subnets with a default route whose `nat_gateway_id` is `aws_nat_gateway.main.id`, then associate that table with the private subnets. NAT Gateways and Elastic IPs can incur charges.

## Identity and permissions

| Terraform resource | Purpose | Closest Azure equivalent |
|---|---|---|
| `aws_iam_role` | Defines an identity that an AWS service or trusted principal can assume. | Managed identity or service principal, depending on the principal and use case. |
| `aws_iam_role_policy` | Adds an inline permissions policy to a role. | Azure role assignment plus a built-in or custom role definition; IAM policy documents do not map one-to-one. |
| `aws_iam_instance_profile` | Makes an IAM role available to an EC2 instance. | Managed identity attached to a virtual machine. |

```hcl
resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "read_s3" {
  name = "read-s3"
  role = aws_iam_role.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:ListBucket"]
      Resource = "arn:aws:s3:::example-bucket"
    }]
  })
}

resource "aws_iam_instance_profile" "example" {
  name = "example-profile"
  role = aws_iam_role.example.name
}
```

For EKS, the cluster and worker nodes also need IAM roles with the AWS-managed permissions required by EKS. Keep policies narrowly scoped; the small policy above is only an illustration.

## Compute and application entry point

| Terraform resource | Purpose | Closest Azure equivalent |
|---|---|---|
| `aws_instance` | Creates a virtual machine (EC2 instance). | Virtual machine (`azurerm_linux_virtual_machine` / `azurerm_windows_virtual_machine`) |
| `aws_lb` | Creates an Application or Network Load Balancer. | Azure Load Balancer or Application Gateway, depending on load-balancer type and layer. |
| `aws_lb_target_group` | Defines targets and health checks for an Application or Network Load Balancer. | Backend pool and health probe on Azure Load Balancer/Application Gateway. |
| `aws_lb_listener` | Defines the port/protocol that accepts traffic and its forwarding action. | Load-balancing rule or Application Gateway listener. |

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0123456789abcdef0" # Replace with a valid AMI in your region.
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
}

resource "aws_lb" "app" {
  name               = "example-app"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
}

resource "aws_lb_target_group" "app" {
  name     = "example-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

The load balancer snippet assumes a second public subnet (`aws_subnet.public_2`) in a different availability zone. A usable application also needs targets registered with the target group and security-group rules that permit the intended traffic.

## Storage and database

| Terraform resource | Purpose | Closest Azure equivalent |
|---|---|---|
| `aws_s3_bucket` | Creates an object storage bucket for files, artifacts, or logs. | Storage account and blob container (`azurerm_storage_account`, `azurerm_storage_container`) |
| `aws_db_subnet_group` | Selects the VPC subnets in which an RDS database can be placed. | No direct equivalent resource; Azure Database networking is configured with a delegated subnet or private endpoint, depending on the service. |
| `aws_db_instance` | Creates a managed relational database instance in Amazon RDS. | Azure Database for PostgreSQL/MySQL or Azure SQL Database, depending on the engine. |

```hcl
resource "aws_s3_bucket" "app_data" {
  bucket = "replace-with-a-globally-unique-bucket-name"
}

resource "aws_db_subnet_group" "app" {
  name       = "example-db-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "app" {
  identifier             = "example-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "app"
  username               = "appuser"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.app.name
  vpc_security_group_ids = [aws_security_group.database.id]
  skip_final_snapshot    = true
}
```

For real environments, avoid putting database passwords directly in Terraform configuration or committing them to Git. Use a secret-management workflow, enable encryption and backups, and choose a deletion/final-snapshot policy deliberately. The example uses `skip_final_snapshot = true` only to keep a disposable learning example simple.

## Kubernetes on AWS (EKS)

| Terraform resource | Purpose | Closest Azure equivalent |
|---|---|---|
| `aws_eks_cluster` | Creates the managed Kubernetes control plane. | Azure Kubernetes Service cluster (`azurerm_kubernetes_cluster`) |
| `aws_eks_node_group` | Creates and manages a group of worker nodes for an EKS cluster. | AKS node pool (`azurerm_kubernetes_cluster_node_pool`) |

```hcl
resource "aws_eks_cluster" "main" {
  name     = "example-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  }
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "example-workers"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
}
```

These EKS snippets depend on IAM roles and policies, a VPC, and subnets in at least two availability zones. They show the core resources only; a working cluster also needs appropriate role policies, networking, access configuration, and (for applications exposed publicly) a load-balancing solution.

## Suggested learning order

1. Finish the VPC, public/private subnets, route tables, routes, and subnet associations already started in `environments/prod/modules/network`.
2. Add security groups and understand how traffic flows between the internet, load balancer, application, and database.
3. Practice IAM roles and least-privilege policies before attaching permissions to compute resources.
4. Deploy a small EC2-based application behind a load balancer.
5. Add S3 and a private RDS database, then learn stateful data protection and secret handling.
6. Build EKS only after the VPC, IAM, and subnet concepts are clear; then deploy a small Kubernetes workload.

## Terraform references

- [AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AzureRM provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
