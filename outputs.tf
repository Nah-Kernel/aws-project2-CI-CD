output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Địa chỉ URL Public của Application Load Balancer để truy cập Web App"
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "Địa chỉ kết nối nội bộ của Database"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL của ECR để cấu hình cho file buildspec vế sau"
}
