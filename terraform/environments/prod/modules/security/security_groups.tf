resource "aws_security_group" "kubernetes_sg" {
  name        = "Kubernetes"
  description = "Kubernetes Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "Kubernetes-SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "kube_sg_egress_rule" {
  security_group_id = aws_security_group.kubernetes_sg.id

  cidr_ipv4   = "10.0.0.0/8"
  ip_protocol = "tcp"
  from_port   = "0"
  to_port     = "443"
}