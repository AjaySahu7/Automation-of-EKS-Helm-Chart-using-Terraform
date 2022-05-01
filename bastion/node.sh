#!/bin/bash

# This script will install EKS prerequisites on Amazon Linux or Amazon Linux 2
# * kubectl
# * aws-iam-authenticator
# * AWS CLI

set -x
sudo apt-get update

runuser -l ubuntu -c 'mkdir -p $HOME/bin'
echo 'export PATH=$HOME/bin:$PATH' >>~/.bashrc

# Install kubectl, if absent
if ! type kubectl >/dev/null 2>&1; then
	runuser -l ubuntu -c 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
	runuser -l ubuntu -c 'chmod +x ./kubectl'
	runuser -l ubuntu -c 'cp kubectl $HOME/bin/ && export PATH=$HOME/bin:$PATH'
	echo 'kubectl installed'
else
	echo 'kubectl already installed'
fi

# aws-iam-authenticator
if ! type aws-iam-authenticator >/dev/null 2>&1; then
	curl -o aws-iam-authenticator "https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/$(uname -s)/amd64/aws-iam-authenticator"
	chmod +x ./aws-iam-authenticator
	cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
	echo 'aws-iam-authenticator installed'
else
	echo 'aws-iam-authenticator already installed'
fi

# AWS CLI
if ! type aws >/dev/null 2>&1; then
	runuser -l ubuntu -c 'curl -o awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip'
	sudo apt install unzip
	runuser -l ubuntu -c 'unzip /home/ubuntu/awscli-bundle.zip'
	#sudo apt-get install python3 -y
	sudo apt-get install python3.8-venv -y
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1
	runuser -l ubuntu -c '/home/ubuntu/awscli-bundle/install -b $HOME/bin/aws'
	echo 'AWS CLI installed'
else
	echo 'AWS CLI already installed'
fi

# kubectx/kubens
if ! type kubectx >/dev/null 2>&1; then
	git clone https://github.com/ahmetb/kubectx /opt/kubectx
	ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
	ln -s /opt/kubectx/kubens /usr/local/bin/kubens
	echo 'kubectx installed'
else
	echo 'kubectx already installed'
fi

# Test if AWS credentials exist
aws sts get-caller-identity

#eksctl 
if ! type eksctl >/dev/null 2>&1; then
   runuser -l ubuntu -c 'curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp'
   runuser -l ubuntu -c 'sudo mv /tmp/eksctl /usr/local/bin'
   runuser -l ubuntu -c 'eksctl version'
   echo 'eksctl installed'
else
   echo 'eksctl has already installed'
fi

sudo apt-get install postgresql-client -y
PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "create user ${app_db_username} with password '${app_db_password}';"
PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "create database ${app_db_name}"
PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "grant all privileges on database ${app_db_name} to ${app_db_username}"

PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "create user ${banking_db_username} with password '${banking_db_password}';"
PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "create database ${banking_db_name}"
PGPASSWORD=${master_pass} psql -h ${host} -U ${master_user}  -c "grant all privileges on database ${banking_db_name} to ${banking_db_username}"

sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo usermod -aG docker ubuntu

curl -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get-helm-3
bash ./get-helm-3
