resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  verify     = true

  values = [
    yamlencode({
      server = {
        service = { type = "LoadBalancer" }
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}