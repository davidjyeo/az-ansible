#!/bin/bash

# Update package index and install dependencies
sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    python3-pip \
    pipx

# Set up Microsoft GPG key and Azure CLI repository
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null

sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

AZ_DIST=$(lsb_release -cs)
echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: ${AZ_DIST}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources

# Add Ansible PPA
sudo apt-add-repository -y ppa:ansible/ansible

# Update package index again to recognize new repositories
sudo apt-get update

# Install Ansible and Azure CLI
sudo apt-get install -y ansible azure-cli

# Create Ansible directory structure
sudo mkdir -p /etc/ansible/{inventories/{production/{hosts,group_vars,host_vars},staging/{hosts,group_vars,host_vars}},group_vars,host_vars,library,module_utils,filter_plugins,roles/{common,webtier,monitoring}}

# Install Python packages using pipx
pipx install pywinrm azure-mgmt-resource azure-identity --include-deps
