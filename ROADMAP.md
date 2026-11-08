# IDP Platform — Roadmap

## Goal
Build an Internal Developer Platform on AWS, based on Backstage, to showcase DevOps/SRE/Platform engineering skills:
Backstage, Istio, Jenkins, ArgoCD, AWS, Terraform, GitHub Actions. Kubernetes (app side) already known.

## Phase 0 — Foundations (Terraform hygiene)
- Remote state: S3 (already) + DynamoDB lock table.
- Enable versioning + SSE on state bucket (uncomment/fix bootstrap/s3.tf).
- Pin provider versions, add `terraform fmt`/`validate` in CI.
- Expand IAM: separate roles per concern (network, eks, iam) instead of one NetworkRole; least privilege.
- Add `dev` environment parity with `prod` (currently only main.tf).
- Outputs: export VPC, subnets, SG IDs for downstream modules.

## Phase 1 — Network hardening (in progress)
Issues in current code:
- Private subnets have no NAT gateway / no egress → EKS nodes can't pull images.
- Security group `kubernetes_sg` has no ingress rules; egress range `0..443` is odd.
- Subnet `for_each` keyed by cidr_block → collision if reused; prefer subnet name keys.
- Region mismatch: bootstrap default `ap-southeast-1` vs project `ap-southeast-2`.
- AZ modulo may land on AZs without capacity; filter by supported AZs.
Tasks:
- Add NAT gateway(s) in public subnets + private route tables.
- Add VPC endpoints (ECR, S3, STS, EKS) to reduce NAT cost.
- Define SGs: control-plane, nodes, ALB, Bastion.
- Add NACLs (optional).

## Phase 2 — EKS cluster
- EKS control plane (managed) in private subnets.
- Managed node groups (or Karpenter) in private subnets.
- Addons: VPC CNI, CoreDNS, kube-proxy, EBS CSI, ALB controller, Cluster Autoscaler.
- IRSA via OIDC provider for pod-level IAM.
- kubectl access via aws-auth / access entries.
- Bootstrap Helm via Terraform (helm provider) or ArgoCD later.

## Phase 3 — GitOps (ArgoCD)
- Install ArgoCD on EKS (Helm) via Terraform or bootstrap script.
- App-of-apps pattern; sync waves for dependencies.
- Separate `argocd/` apps manifests (already have folder).
- Sealed Secrets / External Secrets Operator + AWS Secrets Manager.

## Phase 4 — CI (GitHub Actions + Jenkins)
- GitHub Actions: terraform plan/apply, build & push images to ECR, security scan (tfsec/checkov, trivy).
- Jenkins: pipeline for app deploy via ArgoCD (webhook trigger), optional.
- Image signing (cosign) optional.

## Phase 5 — Service mesh (Istio)
- Install Istio (istioctl/Helm) on EKS.
- Ingress gateway via ALB or Istio gateway.
- mTLS, traffic policies, canary releases.

## Phase 6 — Backstage
- Deploy Backstage on EKS (Helm chart).
- Catalog: services, components, APIs.
- Software templates for scaffolding new services.
- Plugins: Kubernetes, ArgoCD, Jenkins, TechDocs, Cost Insights.
- Auth: GitHub OAuth.

## Phase 7 — Observability & security
- Prometheus + Grafana (kube-prometheus-stack).
- Loki/ELK for logs; Tempo/Jaeger for traces.
- Falco / OPA Gatekeeper for policy.
- AWS GuardDuty, CloudTrail.

## Phase 8 — Portfolio polish
- Architecture diagram, README with screenshots, demo video.
- Runbooks, ADRs, cost estimate, teardown script.

## Suggested next concrete steps
1. Fix Phase 1 (NAT + SGs + region) and `terraform plan`.
2. Add EKS module (Phase 2) — biggest learning value.
3. Stand up ArgoCD (Phase 3) then Backstage (Phase 6).
4. Wire GitHub Actions for terraform + image build (Phase 4).
5. Add Istio (Phase 5) last, as overlay.

## Notes on current terraform checkup
- Bootstrap: IAM role only network perms; will need expansion. S3 state bucket managed manually (commented code). Region default mismatch.
- Network: VPC + 4 subnets + IGW + route tables. Missing NAT. Subnet keying by cidr.
- Security: only one SG with egress; no ingress; not attached to anything.
- Settings: simple region map, fine.
- No EKS, no state locking, no dev parity.
