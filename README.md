# IDP_Platform
This repository contains everything I did to learn more about IDP. In the meantime, it also serves as a warm-up after a year without working as a DevOps Engineer.

## Cost notes (AWS free tier)
- EKS control plane: ~$73/month (NOT free tier). Spin up only when demoing.
- Use `terraform/environments/prod/spinup.ps1` and `teardown.ps1` to control costs.
- Network layer (VPC/subnets) is free. Nodes use t3.small (partially free-tier eligible for 12 months).
- Public IPv4 addresses are now billed (~$0.005/hr each, ~$3.65/mo). NAT EIP + any public node IPs add up; private subnets + NAT avoids per-node IP charges.

## AWS cost estimate
Public estimate: https://calculator.aws/#/estimate?id=5a43f439aa2e0e5aa6369367fce0a685a074ddc9
