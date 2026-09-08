# 1. OpenID Connect Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  # Thumbprints oficiales actualizados de GitHub Actions TLS CA
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a21d2c20e2417730e1be71017830cb857e4e"
  ]
}

# 2. IAM Role that GitHub Actions will assume
resource "aws_iam_role" "github_actions_ecr" {
  name = "dev-github-actions-ecr-role"

  # Trust Policy: Defines WHO is allowed to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # CRITICAL SECURITY CHECK: Only allow pushes coming from YOUR specific repository
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:AVC-09@176427021/task-metrics-api*:*"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 3. IAM Policy granting minimal required access to Amazon ECR
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "dev-github-actions-ecr-push-policy"
  description = "Allows GitHub Actions to log in, build, and push Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Step A: Allow ECR authentication token retrieval
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      # Step B: Allow pushing images ONLY to our specific application repository
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.task_api.arn
      }
    ]
  })
}

# 4. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.github_actions_ecr.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}