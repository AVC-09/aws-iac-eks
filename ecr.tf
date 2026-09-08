# Repository for the FastAPI Application
resource "aws_ecr_repository" "task_api" {
  name                 = "dev-task-metrics-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = lower(var.environment) == "dev" ? true : false

  # Automatically scan images for known security vulnerabilities on push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encryption at rest using AWS managed KMS key
  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Lifecycle Policy: Keep only the last 5 images to save storage costs
resource "aws_ecr_lifecycle_policy" "task_api_policy" {
  repository = aws_ecr_repository.task_api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images and purge older builds"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}