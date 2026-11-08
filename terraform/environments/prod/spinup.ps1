# Spin up the network (incl. NAT gateway), EKS cluster, and ArgoCD for a demo session.
# Run from this directory after `terraform init`.
terraform apply -target=module.network -auto-approve
terraform apply -target=module.eks -auto-approve
terraform apply -target=module.argocd -auto-approve