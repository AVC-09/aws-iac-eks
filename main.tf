# Fetch available Availability Zones in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "task-api-${var.environment}-vpc"
  cidr = var.vpc_cidr

  # Dynamically pick the first 2 AZs available in the region
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Subnet allocation based on architecture design:
  # 2 Public (ALB/NAT) | 2 Private (App/EKS) | 2 Private (Database)
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  # NAT Gateway strategy (single NAT for cost optimization in dev)
  enable_nat_gateway     = true
  single_nat_gateway     = lower(var.environment) == "dev" ? true : false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Automatically create DB subnet group
  create_database_subnet_group = true

  # Special tags required for AWS Load Balancer Controller auto-discovery in EKS
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}