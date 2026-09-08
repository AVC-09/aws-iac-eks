# -----------------------------
# VPC Outputs
# -----------------------------
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets for EKS worker nodes"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "IDs of the private subnets for RDS/ElastiCache"
  value       = module.vpc.database_subnets
}

# -----------------------------
# ElastiCache Redis Outputs
# -----------------------------
output "redis_endpoint" {
  description = "Primary endpoint address for the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Port number on which the Redis cluster accepts connections"
  value       = aws_elasticache_cluster.redis.port
}

# -----------------------------
# EKS Cluster Outputs
# -----------------------------
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# -----------------------------
# Output of the ECR Repository URL needed for Docker and GitHub Actions
# -----------------------------
output "ecr_repository_url" {
  description = "URL of the ECR repository for the FastAPI application"
  value       = aws_ecr_repository.task_api.repository_url
}

# -----------------------------
# Output of the IAM Role ARN for GitHub Actions to assume via OIDC
# -----------------------------
output "github_actions_role_arn" {
  description = "ARN of the IAM Role for GitHub Actions to assume via OIDC"
  value       = aws_iam_role.github_actions_ecr.arn
}