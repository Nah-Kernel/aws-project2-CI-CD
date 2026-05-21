resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

# Target Group BLUE (Traffic thật hiện tại - Cổng 80 của ALB map vào port 8080 container)
resource "aws_lb_target_group" "blue" {
  name        = "${var.environment}-tg-blue"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Bắt buộc đối với Fargate network mode 'awsvpc'

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "8080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Target Group GREEN (Nơi code mới được deploy lên test trước khi switch traffic)
resource "aws_lb_target_group" "green" {
  name        = "${var.environment}-tg-green"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "8080"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# HTTP Listener chuyển tiếp mặc định vào Blue Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  
  lifecycle {
    ignore_changes = [default_action] # CodeDeploy sẽ tự thay đổi action này khi chạy Blue/Green, tránh bị Terraform ghi đè ngược lại
  }
}
