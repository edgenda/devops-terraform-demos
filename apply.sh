#!/bin/bash

set -ex

terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan
ansible-playbook --key-file "demo_key" -i terraform.py playbook.yml
