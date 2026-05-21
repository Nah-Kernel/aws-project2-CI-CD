# ECS Task Execution Role: Dùng bởi ECS Agent để kéo image từ ECR, ghi log CloudWatch, đọc Secrets
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline Policy cho phép Task Execution đọc Secrets Manager
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "AllowReadSecretsAndKMS"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*" # Tránh dùng *, thực tế nên chỉ định chính xác ARN của Secret
      }
    ]
  })
}

# ECS Task Role: Quyền hạn của chính ứng dụng chạy trong container (Ví dụ: ghi file vào S3, gọi DynamoDB...)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Quyền cho CodeBuild và CodePipeline
resource "aws_iam_role" "codebuild_role" {
  name = "${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { 
        Service = [
          "codebuild.amazonaws.com",
          "codepipeline.amazonaws.com" # ĐÃ FIX: Cho phép cả CodePipeline mượn Role này
        ]
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "CodeBuildAndPipelinePolicy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:CreateDeployment",
          # ĐÃ FIX CHỐT HẠ: Bổ sung quyền đọc cấu hình chiến lược Deployment
          "codedeploy:GetDeploymentConfig", 
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "codestar-connections:UseConnection",
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::779035457035:role/production-ecs-task-role",
          "arn:aws:iam::779035457035:role/production-ecs-task-execution-role"
        ]
      }
    ]
  })
}