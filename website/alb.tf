
### ALB ###


### ALB
resource "aws_alb" "main" {
  name               = "${local.full_service_name}"
  subnets            = "${data.terraform_remote_state.vpc.outputs.public_subnets}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ecs_alb.id}"]

  tags = "${local.tags}"

}




### Target Groups ###
resource "aws_alb_target_group" "http" {
  name        = "${local.full_service_name}-http-${random_id.randhex.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  target_type = "ip"

  tags = "${local.tags}"

  # lifecycle {
  #   create_before_destroy = true
  # }

  depends_on = [
    "aws_alb.main"
  ]

  health_check {
    enabled = true
    path = "/"
    protocol = "HTTP"
  }
}

# circumvents duplicate naming errors when replace the ALB by generating a
# small hex value that is unique to the configuration parameters specified
# in "keepters".
resource "random_id" "randhex" {
  keepers = {
    name        = "${aws_alb.main.name}"
    protocol    = "${var.https ? "HTTP" : "HTTPS"}"
    vpc_id      = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
    target_type = "ip"
  }
  byte_length = 4
}



### Listeners ###
resource "aws_alb_listener" "https" {
  # count             = "${var.https ? 1 : 0}"
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "${var.app_ssl_policy}"
  certificate_arn   = "${var.app_certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.http.arn}"
    type             = "forward"

  }
}

resource "aws_alb_listener" "http" {
  # count             = "${var.https ? 0 : 1}"
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.http.arn}"
    type             = "forward"
  }
}


### Security ###
resource "aws_security_group" "ecs_alb" {
  description = "Balancer for ${local.full_service_name}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  name   = "${local.full_service_name}-alb-sg"
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
