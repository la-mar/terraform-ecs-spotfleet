
# %% General
variable "domain" {
  description = "Design domain of this service."
}

variable "environment" {
  description = "Environment Name"
}

variable "service_name" {
  description = "Name of the service"
}

variable "tld" {
  description = "Top level domain name for the service"
}

variable "subdomain" {
  description = "Hosting subdomain name"
}

# %% RDS
variable "backup_retention_period" {
  description = "Length of time to store automated backups"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS Postgres instance"
  default = 40
}

variable "db_max_storage" {
  description = "Max allocated storage for RDS Postgres instance"
  default = 100
}

variable "db_monitoring_interval" {
  description = "Max allocated storage for RDS Postgres instance"
  default = 0
}

variable "enable_monitoring" {
  description = "RDS enable enhanced monitoring"
  default = true
}

variable "db_instance_type" {
  description = "RDS Postgres instance size"
  default = "db.t3.small"
}

variable "db_username" {
  description = "Admin username for RDS instance"
}

variable "db_password" {
  description = "Admin password for RDS instance"
}


# %% Spot Fleet
variable "instance_types" {
  description = "AWS instance type to use"
  default = ["t3.nano", "t3.micro", "t3.small"]
}

variable "key_name" {
  description = "SSH key name"
  default = "ecs-service"
}

variable "volume_size" {
  description = "Root volume size"
  default = 30
}

variable "max_size" {
  default = 3
  description = "Maximum size of the nodes in the cluster"
}

variable "min_size" {
  default = 1
  description = "Minimum size of the nodes in the cluster"
}

variable "desired_capacity" {
  default = 2
  description = "The desired capacity of the cluster"
}

# %% Cloudwatch parameters
variable "enable_alarms" {
  description = "Control to add/remove cloudwatch alarms"
  default = false
}

variable "burst_balance_threshold" {
  description = "The minimum percent of General Purpose SSD (gp2) burst-bucket I/O credits available."
  default = 20
}

variable "cpu_utilization_threshold" {
  description = "The maximum percentage of CPU utilization."
  default = 80
}

variable "cpu_credit_balance_threshold" {
  description = "The minimum number of CPU credits (t2 instances only) available."
  default = 20
}

variable "disk_queue_depth_threshold" {
  description = "The maximum number of outstanding IOs (read/write requests) waiting to access the disk."
  default = 64
}

variable "freeable_memory_threshold" {
  description = "The minimum amount of available random access memory in Byte."
  default = 64000000 # 64MB
}

variable "free_storage_space_threshold" {
  description = "The minimum amount of available storage space in Byte."
  default = 2000000000  # 2GB
}

variable "swap_usage_threshold" {
  description = "The maximum amount of swap space used on the DB instance in Byte."
  default = 256000000 # 256MB
}


# %% ALB
variable "https" {
  description = "Listen over https"
  default = true
}

variable "app_ssl_policy" {
  description = "SSL Policy"
  default = "ELBSecurityPolicy-2015-05"
}

variable "container_port" {
  description = "Port number exposed by container"
  default = 80
}

variable "container_name" {
  description = "Container name to pass to ALB"
}






