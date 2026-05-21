resource "aws_codestarconnections_connection" "github" {
  name          = "${var.environment}-github-conn"
  provider_type = "GitHub"
}

# 1. SỬA CODEBUILD PROJECT: Ép region CloudWatch về chữ thường
resource "aws_codebuild_project" "build" {
  name         = "${var.environment}-codebuild"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true 
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

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket        = "${var.environment}-pipeline-artifacts-${random_string.suffix.result}"
  force_destroy = true
}

# 2. SỬA CODEPIPELINE: Khai báo tường minh Region chữ thường cho TẤT CẢ các Stage Action
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
      provider         = "CodeStarSourceConnection" # ĐÃ FIX: Sai tên provider
      version          = "1"                         # ĐÃ FIX: CodeStarConnection dùng version 1
      output_artifacts = ["source_output"]
      region           = "ap-southeast-1"

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "${var.github_repo_owner}/${var.github_repo_name}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"            # ĐÃ FIX: Bắt buộc để đóng gói mã nguồn từ GitHub
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
      region           = "ap-southeast-1"

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
      region          = "ap-southeast-1"

      configuration = {
        ApplicationName                = "AppECS-${aws_ecs_cluster.main.name}"
        DeploymentGroupName            = "DgpECS-${aws_ecs_service.main.name}"
        TaskDefinitionTemplateArtifact = "build_output"
        AppSpecTemplateArtifact        = "build_output"
        # ĐÃ FIX CHỐT HẠ: Định nghĩa tường minh file cấu hình để hệ thống không bốc nhầm chuỗi trống
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }
}