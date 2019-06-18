
### Database Instance ###
resource "aws_db_instance" "db" {

  identifier = "${local.full_service_name}-db"
  engine               = "postgres"
  name = "postgres"
  engine_version       = "11.2"
  instance_class       = "${var.db_instance_type}"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = "${var.db_username}"
  password             = "${var.db_password}"
  monitoring_interval = 60
  monitoring_role_arn  = "${aws_iam_role.rds_enhanced_monitoring.arn}"
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  copy_tags_to_snapshot = true
  maintenance_window = "Sun:00:00-Sun:03:00"
  backup_retention_period = "${var.backup_retention_period}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]

  deletion_protection = true

  tags = "${local.tags}"

}

### DB Subnet Group ###
resource "aws_db_subnet_group" "default" {
  name       = "${local.full_service_name}-db-sng"
  subnet_ids = "${data.terraform_remote_state.vpc.outputs.database_subnets}"

  tags = "${local.tags}"
}


### Log Group ###


### Security ###
resource "aws_security_group" "db" {
  description = "RDS SG for ${local.full_service_name}"

  vpc_id = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  name   = "${local.full_service_name}-db-sg"
  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


### Enhanved Monitoring ###
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "rds-enhanced_monitoring-role-${local.full_service_name}"
  assume_role_policy = "${data.aws_iam_policy_document.rds_enhanced_monitoring.json}"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = "${aws_iam_role.rds_enhanced_monitoring.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}
















