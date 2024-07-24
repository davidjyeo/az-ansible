#!/bin/bash

# Enable UFW and allow SSH
# sudo ufw enable
# sudo ufw allow ssh

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y

# Install pipx and required packages
sudo apt install -y pipx python3-pip
pipx install ansible pywinrm azure-mgmt-resource azure-cli --include-deps

# Ensure pipx binaries are in PATH
pipx ensurepath

# Create necessary directories for Ansible
sudo mkdir -p /etc/ansible/{inventories/{production/{hosts,group_vars,host_vars},staging/{hosts,group_vars,host_vars}},group_vars,host_vars,library,module_utils,filter_plugins,roles/{common,webtier,monitoring}}

# Install Ansible collections
ansible-galaxy collection install azure.azcollection microsoft.ad community.azure

# Install and upgrade additional Python packages
sudo apt-get install -y python3-oauthlib




# sudo cat << EOF > /etc/ansible/ansible.cfg
# [defaults]
# host_key_checking = False
# EOF


# # Increase size of logical volume rootvg/homelv.
# sudo lvextend -L+10GB /dev/mapper/rootvg-homelv
# sudo xfs_growfs /dev/rootvg/homelv

# # Install Ansible az collection for interacting with Azure.