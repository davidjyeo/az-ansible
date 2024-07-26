#!/bin/bash

set -euo pipefail

# Variables
DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
MICROSOFT_KEYRING="/etc/apt/keyrings/microsoft.gpg"
ARCH=$(dpkg --print-architecture)
DISTRO=$(lsb_release -cs)
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
MICROSOFT_GPG_URL="https://packages.microsoft.com/keys/microsoft.asc"
MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
AWX_OPERATOR_REPO="https://github.com/ansible/awx-operator.git"
NAMESPACE="ansible-awx"
ANSIBLE_PPA="ppa:ansible/ansible"

# Create keyrings directory if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Update package index and install dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    python3-pip \
    pipx

# Add the Docker GPG key and repository
curl -fsSL $DOCKER_GPG_URL | sudo tee $DOCKER_KEYRING >/dev/null
echo "deb [arch=$ARCH signed-by=$DOCKER_KEYRING] https://download.docker.com/linux/ubuntu $DISTRO stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Add the Microsoft GPG key and Azure CLI repository
curl -sLS $MICROSOFT_GPG_URL | gpg --dearmor | sudo tee $MICROSOFT_KEYRING >/dev/null
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: $DISTRO
Components: main
Architectures: $ARCH
Signed-By: $MICROSOFT_KEYRING" | sudo tee /etc/apt/sources.list.d/azure-cli.sources >/dev/null

# Add Ansible PPA
sudo apt-add-repository -y $ANSIBLE_PPA

# Update package index to recognize new repositories
sudo apt-get update

# Install Docker, Ansible, and Azure CLI
sudo apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    ansible \
    azure-cli

# Enable the Docker system service to start automatically at boot time
sudo systemctl enable docker

# Create Ansible directory structure
sudo mkdir -p /etc/ansible/{inventories/{production,staging}/{hosts,group_vars,host_vars},group_vars,host_vars,library,module_utils,filter_plugins,roles/{common,webtier,monitoring}}

# Install Python packages using pipx
pipx install pywinrm azure-mgmt-resource azure-identity --include-deps

# Download and install Minikube
curl -LO $MINIKUBE_URL
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Add the current user to the Docker group and activate it
sudo usermod -aG docker $USER
newgrp docker

# Start Minikube with Docker driver and enable the ingress addon
minikube start --vm-driver=docker --addons=ingress

# Download and install kubectl
curl -LO $KUBECTL_URL
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Clone the AWX Operator repository and checkout the desired version
git clone $AWX_OPERATOR_REPO
cd awx-operator/
git checkout 2.16.1 # Or the latest version

# Deploy AWX Operator
export NAMESPACE
make deploy

# Deploy the AWX demo application
kubectl create -f awx-demo.yml -n $NAMESPACE

# Access the AWX demo service
MINIKUBE_SERVICE_URL=$(minikube service awx-demo-service --url -n $NAMESPACE)
echo "AWX demo service URL: $MINIKUBE_SERVICE_URL"
kubectl port-forward service/awx-demo-service -n $NAMESPACE --address 0.0.0.0 10445:80 &