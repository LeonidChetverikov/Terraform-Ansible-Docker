# Terraform-Ansible-Docker
This repo is educational repo for terraform and provisioning via Ansible
TODO Create Dockerfile for MangoDB cluster

Right now:
1. terraform init
2. terraform plan
3. terraform apply

to create inventory file for Ansible, after terraform apply use terraform output > inventory

For provisioning via ansible ansible-playbook -i inventory --private-key <path to yours pem file>
