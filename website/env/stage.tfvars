
domain = "engineering"

environment = "stage"

tld = "example.com"
subdomain = "my-ecs-service" #becomes my-ecs-service.example.com

service_name = "my-ecs-service"

ami = "ami-01f1db40c7cbd1a37"

backup_retention_period = 7


instance_types = ["t2.small", "t3.small", "t3a.small"]


app_certificate_arn = ""



key_name = "ecs-service"

container_name = "nginx"
container_port = 80

db_instance_type = "db.t3.micro"

sentry_key = ""

django_settings_module = "home.settings.staging"

frontend_tag = "stage"
backend_tag = "stage"


