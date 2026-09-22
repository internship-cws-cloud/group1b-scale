# ==============================================================================
# 1. IAM Policy Document for ECS Task Trust Relationship
# ==============================================================================
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ==============================================================================
# 2. IAM Execution Role (Allows ECS to pull images from ECR & write logs)
# ==============================================================================
resource "aws_iam_role" "exec" {
  name               = "${var.group_name}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# ==============================================================================
# 3. Attach AWS Managed Execution Policy to the Role
# ==============================================================================
resource "aws_iam_role_policy_attachment" "exec" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==============================================================================
# 4. CloudWatch Log Group (Captures app stdout/stderr with 7-day retention)
# ==============================================================================
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.group_name}"
  retention_in_days = 7
}

# ==============================================================================
# 5. Data Lookup for Existing ECR Repository
# ==============================================================================
data "aws_ecr_repository" "app" {
  name = "task-tracker"
}

# ==============================================================================
# 6. ECS Task Definition (Container configuration, environment, & resources)
# ==============================================================================
resource "aws_ecs_task_definition" "web" {
  family                   = "${var.group_name}-task-tracker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256  # 0.25 vCPU
  memory                   = 512  # 0.5 GB
  execution_role_arn       = aws_iam_role.exec.arn

  container_definitions = jsonencode([{
    name      = "web"
    image     = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "APP_VERSION", value = var.image_tag },
      {
        name  = "DATABASE_URL"
        value = "postgresql://tasks:${var.db_password}@${aws_db_instance.tasks.address}:5432/tasks"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ==============================================================================
# 7. ECS Cluster (The logical group that holds running services)
# ==============================================================================
resource "aws_ecs_cluster" "main" {
  name = "${var.group_name}-cluster"
}

# ==============================================================================
# 8. ECS Service (Maintains requested task count, network ENI, & ALB integration)
# ==============================================================================
resource "aws_ecs_service" "web" {
  name            = "${var.group_name}-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
}
