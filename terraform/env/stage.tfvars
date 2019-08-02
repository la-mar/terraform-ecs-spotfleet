
domain = "engineering" # design domain
environment = "staging" # deployment environment name
tld = "example-stage.com" # top level domain name
subdomain = "subdomain" # sub domain for route53
service_name = "ops-website" # name of the implemented service
backup_retention_period = 0 # RDS backup retention duration
instance_types = ["t3.nano", "t3.micro"] # instance types for cluster
desired_capacity = 2 # desired number of cluster instances
key_name = "ecs-service-example" # ssh key name
container_name = "nginx" # container name to be load balanced
container_port = 80 # container port to be load balanced
db_instance_type = "db.t3.micro" # RDS instance type
enable_alarms = false # emable RDS alarms