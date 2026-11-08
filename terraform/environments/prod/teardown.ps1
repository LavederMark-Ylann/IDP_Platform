# Teardown script: destroy the EKS cluster and NAT gateway to stop hourly charges.
# Run from this directory after `terraform init`.
#
# Usage:
#   .\teardown.ps1            # destroy EKS + network (NAT gateway)
#   .\teardown.ps1 -All       # destroy everything in this environment

param(
  [switch]$All
)

if ($All) {
  terraform destroy -auto-approve
} else {
  # Destroy EKS first (depends on network), then network/NAT.
  terraform destroy -target=module.eks -auto-approve
  terraform destroy -target=module.network -auto-approve
}

Write-Host "Teardown complete. EBS volumes, ENIs and EIPs not removed."