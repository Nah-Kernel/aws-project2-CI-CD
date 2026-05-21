resource "aws_db_subnet_group" "db_sn_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "DB Subnet Group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.environment}-postgres"
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # Tiết kiệm chi phí AWS Academy/Free Tier
  db_name                = "webappdb"
  username               = "db_admin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_sn_group.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  multi_az               = false # Bật lên true nếu chạy production thực tế để kích hoạt Multi-AZ
}
