#!/bin/bash

PUBLIC_IP=$1
BACKUP_LOCATION=$([ -z $2 ] && echo "backup" || echo $2)

rsync -av --rsync-path="sudo rsync" --exclude="tls" ec2-user@$PUBLIC_IP:/var/lib/rancher/k3s/server $BACKUP_LOCATION
#rsync -av --rsync-path="sudo rsync" ec2-user@$PUBLIC_IP:/etc/rancher/k3s $BACKUP_LOCATION
