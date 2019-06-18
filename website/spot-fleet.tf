


### Custom User Data ###

data "template_file" "user_data" {
  template = "${file("templates/user_data.sh")}"

  vars = {
   cluster_name = "${local.full_service_name}"
  }
}


### Spot Fleet Request ###

resource "aws_spot_fleet_request" "main" {
  iam_fleet_role                      = "${aws_iam_role.fleet.arn}"
  target_capacity                     = "${var.desired_capacity}"
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = false
  replace_unhealthy_instances         = true
  valid_until                         = "2025-12-04T20:44:20Z"
  fleet_type = "maintain"
  instance_pools_to_use_count = 2
  target_group_arns = [
    # "${aws_alb_target_group.https.arn}",
    "${aws_alb_target_group.http.arn}",
  ]
  load_balancers = [
    "${aws_alb.main.name}"
  ]

  timeouts {
    create = "3m"
  }

  depends_on = ["aws_iam_role_policy_attachment.fleet"]

  dynamic "launch_specification" {
    for_each = "${var.instance_types}"

    content {
      ami                    = "${var.ami}"
      instance_type          = "${launch_specification.value}"
      subnet_id              = "${data.terraform_remote_state.vpc.outputs.private_subnets[0]}"
      vpc_security_group_ids = ["${aws_security_group.ecs_instance.id}"]
      iam_instance_profile   = "${aws_iam_instance_profile.ecs.name}"
      key_name               = "${var.key_name}"
      tags = merge(local.tags, {Name = "${local.full_service_name}"})


      root_block_device {
        volume_type = "gp2"
        volume_size = "${var.volume_size}"
      }

      user_data = "${data.template_file.user_data.rendered}"
    }
  }
}


### Security ###

data "aws_iam_policy_document" "fleet" {
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "spotfleet.amazonaws.com",
        "ec2.amazonaws.com"
      ]
    }

  }
}

resource "aws_iam_role" "fleet" {
  name = "${local.full_service_name}-fleet"

  assume_role_policy = "${data.aws_iam_policy_document.fleet.json}"
}


resource "aws_iam_role_policy_attachment" "fleet" {
  # name = "${local.full_service_name}-fleet"
  role = "${aws_iam_role.fleet.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetRole"
}

