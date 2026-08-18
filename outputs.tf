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

output "redis_endpoint" {
  description = "Primary endpoint address for the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Port number on which the Redis cluster accepts connections"
  value       = aws_elasticache_cluster.redis.port
}