# Configure the Helm provider to authenticate with the EKS cluster
# Configure the Helm provider to authenticate with the EKS cluster
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

# Deploy the AWS Load Balancer Controller using individual set blocks
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  # Timeouts to avoid context deadline exceeded
  timeout       = 600
  wait          = true
  wait_for_jobs = true

  set = [{
    name  = "clusterName"
    value = module.eks.cluster_name
  },
  {
    name  = "serviceAccount.create"
    value = "true"
  },
  {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  },
  {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.aws_lbc_irsa_role.iam_role_arn
  },
  {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }]

  depends_on = [
    module.eks,
    module.aws_lbc_irsa_role
  ]
}