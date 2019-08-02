"""
Example docker deployment to AWS ECS cluster.

The script does the following:

    1. Loads environment variables from the .env

    For each service in SERVICES
    2. Generates a populated ECS task definition
        - You can configure your task definitions in the get_task_definition() method.
    3. Optionally authenticate Docker to ECR
    4. Optionally build any configured containers (see line ~480)
    5. Optionally push any configured containers to ECR
    6. Register the new task definition in ECR
    7. Retrieve the latest task definition revision number
    8. Update the running service with the new task definition and force a new deployment


This script assumes AWS credentials are stored in an environment variable suffixed with
the given environment name. I've found this to be the easiest way to deploy to different
AWS accounts with travis-ci.

    Ex: env_name = dev

        --- .env ---
        export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID_DEV
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_DEV
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_DEV
        ------------

    Ex: env_name = prod

        --- .env ---
        export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID_PROD
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PROD
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PROD
        ------------
"""

import base64
import json
import os
import subprocess
import datetime
import sys

from dotenv import load_dotenv, dotenv_values
import boto3
import docker


load_dotenv(f'.env')

ENV = os.getenv('ENV')
PROJECT_NAME = 'ops-website' # you can set the project name here
QUALIFIED_PROJECT_NAME = f'{PROJECT_NAME}-{ENV}'
CLUSTER_NAME = QUALIFIED_PROJECT_NAME
SERVICE_NAME = QUALIFIED_PROJECT_NAME

# List of component tasks that make up the ECS service
TASKS = [PROJECT_NAME] # you can add more tasks here

# container names
FRONTEND_IMAGE = f'{PROJECT_NAME}-frontend'
BACKEND_IMAGE = f'{PROJECT_NAME}-backend'






print('\n\n' + '-'*30)
print(f'ENV: {ENV}')
print(f'CLUSTER_NAME: {CLUSTER_NAME}')
print(f'SERVICE_NAME: {SERVICE_NAME}')
print(f'TASKS: {TASKS}')
print('-'*30 + '\n\n')

# environment variables to load into the task definition
task_envs = {
    'DB_HOST': os.getenv('DB_HOST', 'localhost'),
    'DB_NAME': os.getenv('DB_NAME', 'postgres'),
    'DB_USER': os.getenv('DB_USER', None),
    'DB_PASSWORD': os.getenv('DB_PASSWORD', None),
    'DB_PORT': os.getenv('DB_PORT', 5432)
}



def transform(d: dict):
    return [{'name': k, 'value': v} for k, v in d.items()]


# get the task definition matching the name parameter
def get_task_definition(
    name: str,
    envs: list,
    account_id: str,
    service_name: str,
    environment: str,
    frontend_image: str,
    backend_image: str
    ):
    defs = {
        'ops-website':
            {
                'containerDefinitions': [
                    {
                        "name": "nginx",
                        "logConfiguration": {
                            "logDriver": "awslogs",
                            "options": {
                                "awslogs-group": f"/ecs/{service_name}-{environment}",
                                "awslogs-region": "us-east-1",
                                "awslogs-stream-prefix": "ecs"
                            }
                        },
                        # "entryPoint": [],
                        "portMappings": [
                            {
                                "hostPort": 80,
                                "containerPort": 80,
                                "protocol": "tcp"
                            },
                            {
                                "hostPort": 443,
                                "containerPort": 443,
                                "protocol": "tcp"
                            }
                        ],
                        # "command": [
                        #     "nginx",
                        #     "-g",
                        #     "daemon off;"
                        # ],
                        "memoryReservation": 128,
                        "image": f"{account_id}.dkr.ecr.us-east-1.amazonaws.com/{frontend_image}:{environment}",
                        "essential": True
                    },
                    {
                        "name": "server",
                        "logConfiguration": {
                            "logDriver": "awslogs",
                            "options": {
                                "awslogs-group": f"/ecs/{service_name}-{environment}",
                                "awslogs-region": "us-east-1",
                                "awslogs-stream-prefix": "ecs"
                            }
                        },
                        # "entryPoint": [],
                        "portMappings": [
                            {
                                "hostPort": 8000,
                                "containerPort": 8000,
                                "protocol": "tcp"
                            }
                        ],
                        # "command": [
                        #     "bash",
                        #     "-c",
                        #     "python manage.py makemigrations && python manage.py migrate && gunicorn home.wsgi -b 0.0.0.0:8000"
                        # ],
                        "environment": transform(envs),
                        "memoryReservation": 128,
                        "image": f"{account_id}.dkr.ecr.us-east-1.amazonaws.com/{backend_image}:{environment}",

                    }

                ],
                'executionRoleArn': 'ecsTaskExecutionRole',
                'family': f'{service_name}-{environment}',
                'networkMode': 'awsvpc',
                'taskRoleArn': 'ecsTaskExecutionRole',
            },
    }

    return defs[name]

class AWSContainerInterface:
    ignore_env = False
    _env_name = None
    access_key_id = None
    secret_access_key = None
    region = None
    account_id = None
    _ecr = None
    _ecs = None
    cluster_name = None
    service_name = None
    _docker_client = None
    _docker_is_authorized = False

    def __init__(self,
                env_name: bool = None,
                ignore_env: bool = False,
                ):
        self.ignore_env = ignore_env
        self._env_name = env_name
        self.credentials_from_envs()

    @property
    def docker_is_authorized(self):
        return self._docker_is_authorized

    @property
    def env_name(self):
        if not self.ignore_env:
            return os.getenv('ENV', self._env_name)
        else:
            return self._env_name

    @property
    def has_credentials(self):
        return all([
            self.access_key_id is not None,
            self.secret_access_key is not None,
            self.region is not None,
            self.account_id is not None,
        ])

    @property
    def ecr_url(self):
        if not self.has_credentials:
            self.credentials_from_envs()
        return f'{self.account_id}.dkr.ecr.{self.region}.amazonaws.com'

    @property
    def docker_client(self):
        return self._docker_client or self._get_docker_client()

    def credentials_from_envs(self, env_name: str = None):
        """Assumes AWS credentials are stored in an environment variable suffixed with
        the given environment name.

            Ex: env_name = dev

                --- .env ---
                export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID_DEV
                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_DEV
                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_DEV
                ------------

            Ex: env_name = prod

                --- .env ---
                export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID_PROD
                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID_PROD
                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY_PROD
                ------------
        """

        env_name = env_name or self.env_name

        if env_name:
            print(f'Retrieving credentials for: {env_name}')
            credentials = {
                'access_key_id': os.getenv(f'AWS_ACCESS_KEY_ID_{env_name.upper()}'),
                'secret_access_key': os.getenv(f'AWS_SECRET_ACCESS_KEY_{env_name.upper()}'),
                'region': os.getenv(f'AWS_REGION_{env_name.upper()}', 'us-east-1'),
                'account_id': os.getenv(f'AWS_ACCOUNT_ID_{env_name.upper()}'),
            }


        else:
            credentials = {
                'access_key_id': os.getenv(f'AWS_ACCESS_KEY_ID'),
                'secret_access_key': os.getenv(f'AWS_SECRET_ACCESS_KEY'),
                'region': os.getenv(f'AWS_REGION', 'us-east-1'),
                'account_id': os.getenv(f'AWS_ACCOUNT_ID'),
            }

        # print(credentials)
        [setattr(self, k, v) for k,v in credentials.items()]

        return credentials

    def get_client(self, service_name: str) -> 'client':

        if not self.has_credentials:
            self.credentials_from_envs()

        return boto3.client(service_name,
                            aws_access_key_id=self.access_key_id,
                            aws_secret_access_key=self.secret_access_key,
                            region_name=self.region)

    def ecs(self):
        return self._ecs or self.get_client('ecs')

    def ecr(self):
        return self._ecr or self.get_client('ecr')

    def _get_docker_client(self, bypass_login: bool = False):

        # if not self.docker_is_authorized and bypass_login:
        docker_client = docker.DockerClient(base_url="unix:///var/run/docker.sock")
        self._docker_login()

        return docker_client


    def _docker_login(self) -> str:
        """Authenticate to AWS in Docker

        Returns:
            dict -- credential mapping from get-login
        """
        os.environ['AWS_ACCOUNT_ID'] = self.account_id
        os.environ['AWS_ACCESS_KEY_ID'] = self.access_key_id
        os.environ['AWS_SECRET_ACCESS_KEY'] = self.secret_access_key
        credentials = subprocess.check_output(
            ['aws', 'ecr', 'get-login', '--no-include-email']).decode('ascii').strip()

        message = os.popen(credentials).read() # execute login in subprocess

        print(message)
        if 'succeeded' in message.lower():
            self._docker_is_authorized = True

        # return credentials

    def update_service(self, cluster_name: str, service_name: str, force = True):

        # force new deployment of ECS service
        print("\n\n"+f"{self.env_name} -- Forcing new deployment to ECS: {self.cluster_name}/{self.service_name}"+"\n\n")
        response = self.ecs().update_service(cluster = cluster_name,
                                service = service_name,
                                forceNewDeployment = force

                                )

        print("\n\n"+f"{self.env_name} -- Exiting ECS deployment update."+"\n\n")
        return self


class DockerImage:
    """ Image should be agnostic to its destination """

    build_context = '.'
    dockerfile = './Dockerfile'
    name = None
    image = None
    image_manager = None

    def __init__(self,
                name: str,
                image_manager: AWSContainerInterface,
                dockerfile: str = None,
                build_context: str = None,
                show_log: str = False,
                tags: list = None
                ):

        self.name = name
        self.image_manager = image_manager
        self.build_context = build_context or self.build_context
        self.dockerfile = dockerfile or self.dockerfile
        self.tags = self.default_tags + (tags or [])

    @property
    def commit_hash(self):
        return subprocess.check_output(['git', 'rev-parse', '--short', 'HEAD']).decode('ascii').strip()

    @property
    def build_date(self):
        return datetime.datetime.now().date()

    @property
    def default_tags(self):
        return [
                'latest',
                f'{self.build_date}',
                self.commit_hash,
                image_manager.env_name,
                ]

    @property
    def client(self):
        return self.image_manager.docker_client

    @property
    def repo_name(self):
        if isinstance(self.image_manager, AWSContainerInterface):
            return f'{self.image_manager.ecr_url}/{self.name}'
        else:
            return None # docker hub url here

    def _logstream(self, source, stream_type: str):

        if stream_type == 'build':
            while True:
                try:
                    output = next(source)
                    if 'stream' in output.keys():
                        print(output['stream'].strip('\n'))
                    else:
                        print(output)
                except StopIteration:
                    break
                except ValueError:
                    print("Error parsing output from docker image build: %s" % output)


        elif stream_type == 'push':
            for chunk in source.split('\r\n'):
                try:
                    if chunk:
                        d = json.loads(chunk)
                        print(d)

                except StopIteration:
                    break
                except ValueError:
                    print("Error parsing output from docker push to ECR: %s" % chunk)

    def build(self, show_log: bool = False):


        self.print_message(f'Building docker image: {self.name}')

        self.image, generator = self.client.images.build(
                                path = self.build_context,
                                dockerfile = self.dockerfile,
                                tag = self.name,
                                )

        if show_log:
            self._logstream(generator, stream_type = 'build')

        self.print_message(f'Docker image build complete: {self.name}')

        return self

    def tag(self, name: str, tag: str):
        self.image.tag(name, tag=tag)
        return self

    def push(self, tag: str = None, show_log: bool = False):

        tag = tag or 'latest'

        self.tag(self.repo_name, tag)

        self.print_message(f'Pushing to remote: {self.repo_name}')

        generator = self.client.images.push(self.repo_name, tag=tag)

        if show_log:
            self._logstream(generator, stream_type = 'push')

        self.print_message('Push complete')

        return self

    def print_message(self, message: str):
        print('\n' + '-'*10 + f' {message} ' + '-'*10 + '\n')

    def deploy(self,
               tag: str = None,
               build: bool = True,
               push: bool = True,
               update_task = True,
               update_service = False,
               show_log: bool = False
                ):

        if build:
            self.build(show_log = show_log)
        else:
            self.image = self.client.images.get(self.name)

        if push:
            self.push(show_log = show_log, tag = tag)


    def deploy_all(self, *args, **kwargs):
        for tag in self.tags:
            self.deploy(tag, *args, **kwargs)

image_manager = AWSContainerInterface(ENV)


# ----------- Uncomment to build and deploy containers inline -----------
#
#
# BUILD = True # optionally rebuild the container before deployment
# PUSH = True # optionally push the container to ECR
#
# i = DockerImage(FRONTEND_IMAGE,
#                 image_manager,
#                 dockerfile = './nginx/Dockerfile',
#                 build_context = '.',
#                 )

# i.deploy_all(build = BUILD, push = PUSH, show_log = True)
#
#
# i = DockerImage(BACKEND_IMAGE,
#                 image_manager,
#                 dockerfile = './ComponentMadness/Dockerfile',
#                 build_context = '.',
#                 )

# i.deploy_all(build = BUILD, push = PUSH, show_log = True)
#
# -----------                       end                       -----------

client = image_manager.ecs()
def get_latest_revision(task_name: str):
    response = client.describe_task_definition(taskDefinition = task_name)
    return response['taskDefinition']['revision']

for service in TASKS:
    print(f'{service}: Creating new task definition')
    cdef = get_task_definition(
                service,
                task_envs,
                image_manager.account_id,
                service_name = service,
                environment = ENV,
                frontend_image = FRONTEND_IMAGE,
                backend_image = BACKEND_IMAGE
                )
    print(f'{service}: Registering new revision in {image_manager.account_id}')
    client.register_task_definition(**cdef)


    rev_num = get_latest_revision(f'{service}-{ENV}')
    print(f'{service}: Updating service to {service}-{ENV}:{rev_num}')
    response = client.update_service(
                        cluster = CLUSTER_NAME,
                        service = SERVICE_NAME,
                        forceNewDeployment = True,
                        taskDefinition = f'{service}-{ENV}:{rev_num}'
                        )
    print(f'{service}: Updated service to {service}-{ENV}:{rev_num}')
