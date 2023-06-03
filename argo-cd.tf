resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.34.6"
  namespace  = "argo-cd"

    values = [
    file("${var.project_dir}/apps/argo-cd/values.yaml")
  ]
}