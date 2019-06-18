


domain = "engineering" # design domain

environment = "dev" # deployment environment name

tld = "example.com"
subdomain = "my-ecs-service" #becomes my-ecs-service.example.com

service_name = "my-ecs-service"

ami = "ami-01f1db40c7cbd1a37" # ECS Optimized Amazon Linux 2

backup_retention_period = 0 # RDS backup retention duration


instance_types = ["t2.small", "t3.small", "t3a.small"] # Instance types for spot fleet

https = true


app_certificate_arn = "" # Ex. arn:aws:acm:us-east-1:ACCOUNT_NUMBER:certificate/ACM_ID


key_name = "ecs-service"

container_name = "nginx" # container name to be load balanced
container_port = 80 # container port to be load balanced

db_instance_type = "db.t3.micro" # RDS instance type

sentry_key = "" # sentry monitoring

django_settings_module = "home.settings.staging" # django

frontend_tag = "dev"
backend_tag = "dev"
