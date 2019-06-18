# Using a single workspace:
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "YOUR_ORGANIZATION"

    workspaces {
      prefix = "${var.service_name}-"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "${replace("${var.environment}", "stage", "dev")}" # remaps stage to use dev network
}

locals {

  backend  = "${var.service_name}-backend"
  frontend = "${var.service_name}-frontend"

  backend_image = "${local.backend}:${var.backend_tag}"
  frontend_image = "${local.frontend}:${var.frontend_tag}"

  full_service_name = "${var.service_name}-${var.environment}"

  tags = {
    environment         = "${var.environment}"
    terraform           = true
    domain              = "${var.domain}"
    service_name        = "${var.service_name}"
    propagate_at_launch = true
  }
}



# Load VPC Data Source
data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "YOUR_ORGANIZATION"

    workspaces = {
      name = "networking-${replace("${var.environment}", "stage", "dev")}" # remaps stage to use dev network
    }
  }
}


# Get current account id that terraform is running under
data "aws_caller_identity" "current" {

}
















