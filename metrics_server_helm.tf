# Deploy Kubernetes Metrics Server using the official Helm chart
resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "kube-system"
  version          = "3.12.1"

  # Ensure the release waits until the deployment is ready
  wait          = true
  wait_for_jobs = true
  timeout       = 300

  depends_on = [
    module.eks
  ]
}