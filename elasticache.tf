# Security Group to restrict access to Redis (Only allow traffic inside the VPC)
resource "aws_security_group" "redis_sg" {
  name        = "${var.environment}-redis-sg"
  description = "Allow inbound traffic to Redis from VPC subnets"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow Redis port from VPC CIDR"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-redis-sg"
  }
}

# Subnet Group associating Redis with the private database subnets created by the VPC module
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = module.vpc.database_subnets
}

# Redis ElastiCache Cluster (Single-node cluster for DEV environment cost optimization)
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-task-metrics-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro" # Cost-effective Graviton-based instance for Dev
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_sg.id]

  tags = {
    Name = "${var.environment}-redis-cluster"
  }
}