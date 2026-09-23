The developing infrastructure contains the following
WSL ubuntu (Kubernetes mononode cluster)
WSL debian (client machine; Helm, Ansible, Terraform)
LocalStack running on the Kubernetes cluster to simulate the services from AWS (Terraform dev env)

The "production" infrastructure
WSL debian (client machine; Helm, Ansible, Terraform)
AWS (EKS)