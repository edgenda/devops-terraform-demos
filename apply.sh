#!/bin/bash

set -ex

terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan
ansible-playbook --key-file "~/.ssh/id_rsa_lab" -i terraform.py playbook.yml
