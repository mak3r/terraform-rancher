#!/bin/bash

PUBLIC_IP=$1

rsync -av --rsync-path="sudo rsync" ec2-user@$PUBLIC_IP:/var/lib/rancher/k3s/server backup
rsync -av --rsync-path="sudo rsync" ec2-user@$PUBLIC_IP:/etc/rancher/k3s backup
