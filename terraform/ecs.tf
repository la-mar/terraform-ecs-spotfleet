### ECS Cluster ###

resource "aws_ecs_cluster" "main" {
  name = local.full_service_name
  tags = local.tags
}

### ECS Services ###
resource "aws_ecs_service" "ops" {
  name            = local.full_service_name
  cluster         = aws_ecs_cluster.main.arn
  task_definition = data.aws_ecs_task_definition.ops.family

  # iam_role        = "${aws_iam_role.ecs_service.arn}"
  scheduling_strategy     = "DAEMON"
  enable_ecs_managed_tags = true
  propagate_tags          = "TASK_DEFINITION"
  tags                    = local.tags

  network_configuration {
    subnets          = data.terraform_remote_state.vpc.outputs.private_subnets
    security_groups  = [aws_security_group.ecs_alb.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.http.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    # create_before_destroy = true
    ignore_changes = [
      desired_count,
      task_definition,
    ]
  }
}

resource "aws_ecs_service" "datadog" {
  name                    = "datadog"
  cluster                 = aws_ecs_cluster.main.arn
  task_definition         = data.aws_ecs_task_definition.datadog.family
  scheduling_strategy     = "DAEMON"
  enable_ecs_managed_tags = true
  propagate_tags          = "TASK_DEFINITION"
  tags                    = local.tags

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [
      desired_count,
      task_definition,
    ]
  }
}

### Task Definitions ###
# task definition must be existing in the AWS account
data "aws_ecs_task_definition" "datadog" {
  task_definition = "datadog"
}

# task definition must be existing in the AWS account
data "aws_ecs_task_definition" "ops" {
  task_definition = local.full_service_name
}

### Security ###

resource "aws_iam_role_policy_attachment" "ecs_service" {
  # name       = "${local.full_service_name}-ecs-service"
  role       = aws_iam_role.ecs_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service" {
  name = "${local.full_service_name}-ecs-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_policy.json
  tags = local.tags
}

resource "aws_security_group" "ecs_instance" {
  name        = "${local.full_service_name}-ecs-instance-sg"
  description = "container security group for ${local.full_service_name}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  tags        = local.tags

  ingress {
    description = "All TCP from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "TCP"
    security_groups = [aws_security_group.ecs_alb.id]
  }

  egress {
    description = "All Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${local.full_service_name}-ecs-instance"
  role = aws_iam_role.ecs_instance.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  role       = aws_iam_role.ecs_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"

}

data "aws_iam_policy_document" "ecs_instance" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ecs_instance" {
  name = "${local.full_service_name}-ecs-instance"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance.json
  tags = local.tags
}

