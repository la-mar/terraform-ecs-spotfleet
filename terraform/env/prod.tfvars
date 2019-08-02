
domain = "engineering" # design domain
environment = "prod" # deployment environment name
tld = "example-production.com" # top level domain name
subdomain = "subdomain" # sub domain for route53
service_name = "ops-website" # name of the implemented service
backup_retention_period = 0 # RDS backup retention duration
instance_types = ["t3.large", "t3.xlarge"] # instance types for cluster
desired_capacity = 6 # desired number of cluster instances
key_name = "ecs-service-example" # ssh key name
container_name = "nginx" # container name to be load balanced
container_port = 80 # container port to be load balanced
db_instance_type = "db.t3.large" # RDS instance type
enable_alarms = true # emable RDS alarms