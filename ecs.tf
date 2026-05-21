resource "aws_ecr_repository" "app" {
  name                 = "${var.environment}-app-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true } # Đảm bảo quét lỗ hổng bảo mật ảnh Docker tự động
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-task-def"
  network_mode             = "awsvpc" # Chế độ mạng bắt buộc cho Fargate giúp gán riêng IP cho từng Task
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "web-container"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.environment}-app"
        "awslogs-region"        = lower(var.aws_region)
        "awslogs-stream-prefix" = "web"
      }
    }
    # Injection DB credentials an toàn từ Secrets Manager vào thẳng Environment Variables của Container
    secretOptions = []
    environment = [
      { name = "DB_HOST", value = aws_db_instance.postgres.address }
    ]
  }])
}

resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/${var.environment}-app"
  retention_in_days = 7
}

resource "aws_ecs_service" "main" {
  name            = "${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false # Bảo mật tuyệt đối, Task nằm ẩn hoàn toàn trong Private Subnet
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "web-container"
    container_port   = 8080
  }

  deployment_controller {
    type = "CODE_DEPLOY" # Ủy quyền kiểm soát Deployment cho AWS CodeDeploy (phục vụ Blue/Green)
  }

  # ĐÃ FIX: Bẻ gãy xung đột, cấm Terraform đè lên các thay đổi do CodeDeploy tự hoán đổi khi chạy luồng Blue/Green
  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer
    ]
  }

  depends_on = [aws_lb_listener.http]
}
