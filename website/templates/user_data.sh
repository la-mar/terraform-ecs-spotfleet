#!/bin/bash
/root/.deploy.sh
# Configure sudo for AD users
echo "%dst-ado-posix             ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/01-ado-sudo
restorecon -R -v /etc/sudoers.d/
# Install Docker
yum update -y
#yum install -y docker
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --add-repo http://dl.fedoraproject.org/pub/epel/7/x86_64/
yum-config-manager --enable docker-ce-edge
yum-config-manager --enable docker-ce-test
yum install pigz -y
yum install docker-ce-17.06.1.ce -y
systemctl start docker
yum-config-manager --disable docker-ce-edge
yum-config-manager --disable docker-ce-test
#Install CloudWatch agent
mkdir /etc/awslogs
touch /etc/awslogs/awslogs.conf
#state folder
mkdir /var/lib/awslogs
# Inject the CloudWatch Logs configuration file contents

curl https://s3.amazonaws.com//aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
chmod +x ./awslogs-agent-setup.py
./awslogs-agent-setup.py -n -r us-east-1 -c /etc/awslogs/awslogs.conf

# Create directories for ECS agent
mkdir -p /var/log/ecs /var/lib/ecs/data /etc/ecs

# Write ECS config file
cat << EOF > /etc/ecs/ecs.config
ECS_DATADIR=/data
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_LOGLEVEL=info
ECS_CLUSTER=${cluster_name}
EOF

cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${cluster_name}-/var/log/dmesg
log_stream_name = ${cluster_name}

[/var/log/messages]
file = /var/log/messages
log_group_name = ${cluster_name}-/var/log/messages
log_stream_name = ${cluster_name}
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = ${cluster_name}-/var/log/docker
log_stream_name = ${cluster_name}
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log.*
log_group_name = ${cluster_name}-/var/log/ecs/ecs-init.log
log_stream_name = ${cluster_name}
datetime_format = %Y-%m-%dT%H:%M:%SZ
+
[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = ${cluster_name}-/var/log/ecs/ecs-agent.log
log_stream_name = ${cluster_name}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = ${cluster_name}-/var/log/ecs/audit.log
log_stream_name = ${cluster_name}
datetime_format = %Y-%m-%dT%H:%M:%SZ

EOF


start ecs