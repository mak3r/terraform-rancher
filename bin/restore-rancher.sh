#!/bin/bash

PUBLIC_IP=$1

ssh -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP 'sudo mkdir -p /var/lib/rancher/k3s'
ssh ec2-user@$PUBLIC_IP 'sudo mkdir -p /etc/rancher'
rsync -av --super --rsync-path="sudo rsync" backup/server ec2-user@$PUBLIC_IP:/var/lib/rancher/k3s 
rsync -av --super --rsync-path="sudo rsync" backup/k3s ec2-user@$PUBLIC_IP:/etc/rancher
