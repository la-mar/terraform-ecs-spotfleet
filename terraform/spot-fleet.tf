### Custom User Data ###

# %% user data for instance bootstrapping
data "template_file" "user_data" {
  template = file("templates/user_data.sh")

  vars = {
    cluster_name = aws_ecs_cluster.main.name # must match name of ecs cluster
  }
}

# %% ECS Optimized AMI
data "aws_ami" "latest_ecs" {
  most_recent = true
  owners      = ["591542846629"] # AWS

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

### Spot Fleet Request ###
resource "aws_spot_fleet_request" "main" {
  iam_fleet_role                      = aws_iam_role.fleet.arn
  target_capacity                     = var.desired_capacity
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = true
  replace_unhealthy_instances         = true
  valid_until                         = "2025-12-04T20:44:20Z"
  fleet_type                          = "maintain"
  instance_pools_to_use_count         = 3

  target_group_arns = [
    aws_alb_target_group.http.arn, # only needs to point at http as ssl is terminated at alb
  ]

  load_balancers = [
    aws_alb.main.name
  ]

  timeouts {
    create = "3m"
  }

  depends_on = ["aws_iam_role_policy_attachment.fleet"]

  dynamic "launch_specification" {
    for_each = var.instance_types

    content {
      ami                    = data.aws_ami.latest_ecs.id
      instance_type          = launch_specification.value
      subnet_id              = data.terraform_remote_state.vpc.outputs.private_subnets[0]
      vpc_security_group_ids = [aws_security_group.ecs_instance.id]
      iam_instance_profile   = aws_iam_instance_profile.ecs.name
      key_name               = var.key_name
      tags = merge(local.tags, {Name = local.full_service_name})

      root_block_device {
        volume_type = "gp2"
        volume_size = var.volume_size
      }

      user_data = data.template_file.user_data.rendered
    }
  }
}

### Security ###

data "aws_iam_policy_document" "fleet" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "spotfleet.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "fleet" {
  name = "${local.full_service_name}-fleet"
  assume_role_policy = data.aws_iam_policy_document.fleet.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fleet" {
  role       = aws_iam_role.fleet.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole"
}

