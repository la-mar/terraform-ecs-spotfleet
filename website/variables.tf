
variable "domain" {
  description = "Design domain of this service."
  default     = "testing"
}
variable "environment" {
  description = "Environment Name (usually dev/stage/prod)"
  default     = "dev"
}

variable "service_name" {
  description = "Name of the service"
  default     = "test-service-dev"
}

variable "instance_type" {
  description = "AWS instance type to use"
  default     = "t3.small"
}

variable "subdomain" {
  description = "Hosting subdomain name"
  default     = "testing"
}

variable "backup_retention_period" {
  description = "Length of time to store automated backups"
}

variable "ecs_cluster_name" {
  description = "The name of the Amazon ECS cluster."
  default     = "test"
}

variable "key_name" {
  description = "Name of the service"
  default     = "ecs-service"
}

## Cluster parameters
variable "ami" {
  default = "ami-00cf4737e238866a3" # ecs optimized ami
  type    = "string"
}

variable "enable_monitoring" {
  type    = "string"
  default = true
}

## Service discovery parameters
variable "service_discovery_enabled" {
  type    = "string"
  default = false
}

variable "service_registration_enabled" {
  type    = "string"
  default = "false"
}
variable "instance_types" {
  description = "AWS instance type to use"
  default     = ["t3.nano", "t3.micro", "t3.small"]
  type        = "list"
}

variable "volume_size" {
  description = "Root volume size"
  default     = 30
}

variable "max_size" {
  default     = 3
  description = "Maximum size of the nodes in the cluster"
}
variable "min_size" {
  default     = 1
  description = "Minimum size of the nodes in the cluster"
}
variable "desired_capacity" {
  default     = 2
  description = "The desired capacity of the cluster"
}

variable "alb_tg_port" {
  description = "The port the load balancer uses when routing traffic to targets in target group"
  default     = 80
}

variable "https" {
  description = "Listen over https"
  default     = true
}

variable "app_certificate_arn" {
  description = "SSL cert ARN"
  default     = ""
}

variable "app_ssl_policy" {
  description = "SSL Policy"
  default     = "ELBSecurityPolicy-2015-05"
}

variable "container_port" {
  description = "Port number exposed by container"
  default     = 80
}

variable "container_name" {
  description = "Container name to pass to ALB"
}


variable "db_instance_type" {
  description = "RDS Postgres instance size"
  default     = "db.t3.small"
}

variable "db_username" {
  description = "Password to RDS Postgres instance"
}

variable "db_password" {
  description = "Password to RDS Postgres instance"
}

variable "django_settings_module" {
  description = "Django settings configuration"
}

variable "sendgrid_key" {
  description = "Sendgrid API key"
}

variable "sentry_key" {
  description = "Sentry API Key"
}

variable "tld" {
  description = "Top level domain name for the service"
}

variable "backend_tag" {
  description = "Tag name of backend image to use"
}

variable "frontend_tag" {
  description = "Tag name of frontend image to use"
}


