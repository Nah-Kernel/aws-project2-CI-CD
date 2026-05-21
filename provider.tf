terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Không khai báo backend S3 nữa -> Terraform sẽ tự lưu state an toàn ở máy bạn
}

provider "aws" {
  region = lower(var.aws_region)
}
