#!/bin/sh

set -x 

RKE2_CHANNEL=$1
RK2_CHANNEL= [ -n $RKE2_CHANNEL ] && echo "$RKE2_CHANNEL" || echo "v1.23"

PUBLIC_IP=$2

mkdir -p rke2-config
mkdir -p ~/.kube

cat > rke2-config/config.yaml << EOF
write-kubeconfig: "/home/{USER}/.kube/config" 
write-kubeconfig-mode: "0600"
tls-san:
  - "$PUBLIC_IP"
  - "{HOSTNAME}"
EOF
sed -i""  "s/{USER}/$(whoami)/" rke2-config/config.yaml
sed -i""  "s/{HOSTNAME}/$(hostname)/" rke2-config/config.yaml

sudo mkdir -p /etc/rancher/rke2
sudo cp rke2-config/config.yaml /etc/rancher/rke2/config.yaml
sudo sh -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=$RKE2_CHANNEL sh -'
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
sleep 10 #sleep 10 seconds before trying to access the kubeconfig file
ME=$(whoami); MYID=$(id -gn); sudo chown $ME:$MYID ~/.kube/config
