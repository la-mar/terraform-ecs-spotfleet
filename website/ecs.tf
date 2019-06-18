









### ECS Cluster ###

resource "aws_ecs_cluster" "main" {
  name = "${local.full_service_name}"
}



### ECS Services ###
resource "aws_ecs_service" "ops" {
  name = "${local.full_service_name}-ecs-service"
  cluster = "${aws_ecs_cluster.main.arn}"
  task_definition = "${aws_ecs_task_definition.ops.arn}"
  # iam_role        = "${aws_iam_role.ecs_service.arn}"
  scheduling_strategy = "DAEMON"
  # enable_ecs_managed_tags = true
  # propagate_tags = "TASK_DEFINITION"


  network_configuration {
    subnets = "${data.terraform_remote_state.vpc.outputs.private_subnets}"
    security_groups = ["${aws_security_group.ecs_alb.id}"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.http.arn}"
    container_name = "${var.container_name}"
    container_port = "${var.container_port}"
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    create_before_destroy = true
    ignore_changes = ["desired_count"]
  }
}

resource "aws_ecs_service" "datadog" {
  name = "datadog-ecs-service"
  cluster = "${aws_ecs_cluster.main.arn}"
  task_definition = "${aws_ecs_task_definition.datadog.arn}"
  # iam_role        = "${aws_iam_role.ecs_service.arn}"
  scheduling_strategy = "DAEMON"
  # enable_ecs_managed_tags = true
  # propagate_tags = "TASK_DEFINITION"

  depends_on = ["aws_iam_role_policy_attachment.ecs_service"]

  network_configuration {
    subnets = "${data.terraform_remote_state.vpc.outputs.private_subnets}"
    security_groups = ["${aws_security_group.ecs_alb.id}"]
    assign_public_ip = false
  }

  # Optional: Allow external changes without Terraform plan difference
  lifecycle {
    create_before_destroy = true
    ignore_changes = ["desired_count"]
  }
}



### Task Definitions ###

resource "aws_ecs_task_definition" "ops" {
  # TODO: Create empty task and create new version in CI deployment
  family = "${local.full_service_name}-ecs-task"
  container_definitions = templatefile("templates/webserver.json", {
    django_settings_module = var.django_settings_module
    environment = var.environment
    sendgrid_key = var.sendgrid_key
    full_service_name = local.full_service_name
    sentry_key = var.sentry_key
    db_host = aws_route53_record.db.name #aws_db_instance.db.address
    db_port = aws_db_instance.db.port
    db_name = aws_db_instance.db.name
    db_username = var.db_username
    db_password = var.db_password
    account_id = data.aws_caller_identity.current.account_id
    backend_image = local.backend_image
    frontend_image = local.frontend_image
  })
  network_mode = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = local.tags

  volume {
    name = "service-storage"
    host_path = "/ecs/service-storage"
  }
}

resource "aws_ecs_task_definition" "datadog" {

  family = "datadog-ecs-task"
  container_definitions = templatefile("templates/datadog.json", {})
  network_mode = "awsvpc"
  requires_compatibilities = ["EC2"]
  tags = local.tags

  volume {
    name = "service-storage"
    host_path = "/ecs/service-storage"
  }
  volume {
    name = "docker_sock"
    host_path = "/var/run/docker.sock"
  }
  volume {
    name = "proc"
    host_path = "/proc/"
  }
  volume {
    name = "cgroup"
    host_path = "/sys/fs/cgroup/"
  }
  volume {
    name = "pointdir"
    host_path = "/opt/datadog-agent/run"
  }
  volume {
    name = "passwd"
    host_path = "/etc/passwd"
  }


}

### Security ###

resource "aws_iam_role_policy_attachment" "ecs_service" {
  # name       = "${local.full_service_name}-ecs-service"
  role     = "${aws_iam_role.ecs_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service" {
  name = "${local.full_service_name}-ec2-service"

  assume_role_policy = "${data.aws_iam_policy_document.ecs_policy.json}"
}


resource "aws_security_group" "ecs_instance" {
  name = "${local.full_service_name}-ecs-instance"
  description = "container security group for ${local.full_service_name}"
  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "TCP"
    security_groups = ["${aws_security_group.ecs_alb.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "ecs" {
  name = "${local.full_service_name}-ecs-instance"
  role = "${aws_iam_role.ecs_instance.name}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  # name       = "${local.full_service_name}-ecs-instance"
  role      = "${aws_iam_role.ecs_instance.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

data "aws_iam_policy_document" "ecs_instance" {
  statement {
    sid = "1"
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }

  }
}

resource "aws_iam_role" "ecs_instance" {
  name = "${local.full_service_name}-ecs-instance"
  path = "/"

  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance.json}"
}


### Log Group ###
resource "aws_cloudwatch_log_group" "loggroup" {
  name = "/ecs/${local.full_service_name}"
  retention_in_days = 3
  tags = "${local.tags}"
}

