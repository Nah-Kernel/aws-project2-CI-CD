# ALB Security Group: Nhận traffic HTTP/HTTPS từ Internet
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Allow inbound public traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group: CHỈ NHẬN TRAFFIC TỪ ALB (Zero Trust Isolation)
resource "aws_security_group" "ecs" {
  name        = "${var.environment}-ecs-tasks-sg"
  description = "Isolate ECS tasks, allow input only from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8080 # Port chạy trong Docker container của Web App
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Cần ra internet qua NAT để kết nối ECR, Secrets Manager
  }
}

# Database Security Group: CHỈ NHẬN TRAFFIC TỪ ECS TASKS
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allow database traffic strictly from ECS containers"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
