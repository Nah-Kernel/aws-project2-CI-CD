# 1. Khởi tạo một Kết nối an toàn đến GitHub (Version 2)
# Sau khi chạy lệnh terraform apply, bạn chỉ cần lên AWS Console bấm "Handshake/Xác nhận" kết nối này 1 lần duy nhất.
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.environment}-github-conn"
  provider_type = "GitHub"
}

# 2. CodeBuild Project phục vụ build Docker image
resource "aws_codebuild_project" "build" {
  name         = "${var.environment}-codebuild"
  service_role = aws_iam_role.codebuild_role.arn

  # SỬA LỖI: Chuyển về đúng cú pháp block cho artifacts
  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # BẮT BUỘC ĐỂ BUILD DOCKER TRONG DOCKER
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "REPOSITORY_URL"
      value = aws_ecr_repository.app.repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# 3. S3 Artifact Bucket cho Pipeline (Tự động tạo hậu tố ngẫu nhiên để tránh trùng tên toàn cầu)
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "${var.environment}-pipeline-artifacts-${random_string.suffix.result}"
  force_destroy = true
}

# 4. AWS CodePipeline định nghĩa luồng CI/CD hoàn chỉnh
resource "aws_codepipeline" "pipeline" {
  name     = "${var.environment}-full-pipeline"
  role_arn = aws_iam_role.codebuild_role.arn 

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarConnections" # Nâng cấp lên kết nối bảo mật V2
      version          = "2"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName                = "AppECS-${aws_ecs_cluster.main.name}"
        DeploymentGroupName            = "DgpECS-${aws_ecs_service.main.name}"
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact        = "build_output"
      }
    }
  }
}
