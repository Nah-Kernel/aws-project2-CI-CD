variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
  description = "AWS Region triển khai hạ tầng"
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Môi trường triển khai"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "github_repo_owner" {
  type        = string
  description = "Tài khoản hoặc Tổ chức GitHub (e.g., 'cloud-cybersecurity-mentor')"
}

variable "github_repo_name" {
  type        = string
  description = "Tên repository chứa mã nguồn ứng dụng"
}

variable "github_branch" {
  type        = string
  default     = "main"
}
