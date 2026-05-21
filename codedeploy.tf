# 1. Khởi tạo CodeDeploy Application dành cho ECS
resource "aws_codedeploy_app" "ecs_app" {
  name             = "AppECS-production-ecs-cluster"
  compute_platform = "ECS"
}

# 2. Tạo IAM Role dành riêng cho CodeDeploy để điều phối ECS và ALB
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })
}

# Gắn Policy chuẩn của AWS để CodeDeploy có quyền tráo đổi traffic trên ECS/ALB
resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# 3. Tạo Deployment Group cấu hình luồng chạy Blue/Green
resource "aws_codedeploy_deployment_group" "ecs_dgp" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "DgpECS-production-ecs-service"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.main.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn] # Port chính chạy ứng dụng
      }

      target_group {
        name = aws_lb_target_group.blue.name # Target Group Blue hiện tại
      }

      target_group {
        name = aws_lb_target_group.green.name # Target Group Green dự phòng để tráo đổi
      }
    }
  }
}
