#!/bin/bash

PUBLIC_IP=$1
BACKUP_LOCATION=$([ -z $2 ] && echo "backup" || echo $2)

ssh -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP 'sudo mkdir -p /var/lib/rancher/k3s'
ssh ec2-user@$PUBLIC_IP 'sudo mkdir -p /etc/rancher'
rsync -av --super --rsync-path="sudo rsync" $BACKUP_LOCATION/server ec2-user@$PUBLIC_IP:/var/lib/rancher/k3s 
rsync -av --super --rsync-path="sudo rsync" $BACKUP_LOCATION/k3s ec2-user@$PUBLIC_IP:/etc/rancher
