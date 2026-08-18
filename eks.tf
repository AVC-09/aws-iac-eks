module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.environment}-eks-cluster"
  kubernetes_version = "1.33" # Modern supported Kubernetes version

  # EKS Cluster Endpoint Access Configuration
  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # Worker nodes live in private app subnets

  # Essential EKS Addons installed BEFORE worker nodes compute starts
  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  # Managed Node Group Configuration
  eks_managed_node_groups = {
    initial = {
      ami_type = "AL2023_ARM_64_STANDARD"

      min_size     = 1
      max_size     = 3
      desired_size = 2

      # Cost-effective ARM-based Graviton instances for Dev workloads
      instance_types = ["t4g.medium"]
      capacity_type  = "SPOT" # Uses AWS Spot instances to reduce costs in DEV

      labels = {
        Environment = var.environment
      }
    }
  }

  # Cluster Access Management (Grants admin rights to the IAM entity executing Terraform)
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}