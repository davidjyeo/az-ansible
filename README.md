# Ansible Automation Deployment into Azure Cloud Environment
> **WORK IN PROGRESS**

> **ROUGH DRAFT**

This repository contains the configuration scripts and documentation for setting up a hybrid cloud environment using Ansible. The environment includes an Ansible Controller Server running on Ubuntu 24.04, a Windows 2022 Domain Controller, an Azure Firewall, and utilizes OpenID Connect (OIDC) for Service Principal Name (SPN) connectivity.

## Prerequisites

Before you begin, ensure you have the following:

- **Ansible 2.14 or later** installed on the controller server.
- **Azure CLI** installed and configured on the Ansible Controller Server.
- **Administrative access** to an Azure account.
- **Access to a Windows Server 2022** for domain controller configuration.
- **OIDC Configuration**: Azure AD setup for OIDC.

## Environment Overview

1. **Ansible Controller Server**: Ubuntu 24.04.
2. **Windows 2022 Domain Controller**: This will be provisioned using an Ansible Playbook.
3. **Networking:** One VNet, Two Subnets and One Public IP
4. **Azure Firewall**: DNAT and Network Rules
5. **OIDC for SPN Connectivity**: Terraform deployment uses SPN with Federated Identity.

## Ubuntu Setup Instructions

### Ansible Controller Server

1. **Install Ansible on Ubuntu 24.04**:

```bash
# !/bin/bash

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
curl -sLS <https://packages.microsoft.com/keys/microsoft.asc> | \
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
```
