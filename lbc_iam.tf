# 1. Download recomended IAM policy for Load Balancer Controller
data "http" "aws_lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# 2. Create the IAM policy for the Load Balancer Controller using the downloaded JSON
resource "aws_iam_policy" "aws_lbc" {
  name        = "AWSLoadBalancerControllerIAMPolicy-dev"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller in EKS"
  policy      = data.http.aws_lbc_iam_policy.response_body
}

# 3. Create the IAM role associated with the Kubernetes ServiceAccount (IRSA)
module "aws_lbc_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "aws-load-balancer-controller-dev"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}