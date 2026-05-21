resource "random_password" "db_password" {
  length  = 16
  special = false # Tránh lỗi ký tự lạ khi pass qua chuỗi kết nối URI của DB
}

resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.environment}-database-credentials-v1"
  recovery_window_in_days = 0 # Xóa ngay lập tức nếu destroy để tránh xung đột tên khi re-run lab
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "db_admin"
    password = random_password.db_password.result
    dbname   = "webappdb"
    host     = aws_db_instance.postgres.address
    port     = 5432
  })
}
