#!/bin/sh

K3S_CHANNEL=$1
K3S_CHANNEL= [ -n $K3S_CHANNEL ] && echo "$K3S_CHANNEL" || echo "v1.23"

PUBLIC_IP=$2

mkdir -p k3s-config
mkdir -p ~/.kube

cat > k3s-config/config.yaml << EOF
write-kubeconfig: "/home/{USER}/.kube/config" 
write-kubeconfig-mode: "0600"
tls-san:
  - "$PUBLIC_IP"
  - "{HOSTNAME}"
EOF
sed -i""  "s/{USER}/$(whoami)/" k3s-config/config.yaml
sed -i""  "s/{HOSTNAME}/$(hostname)/" k3s-config/config.yaml

sudo mkdir -p /etc/rancher/k3s
sudo cp k3s-config/config.yaml /etc/rancher/k3s/config.yaml
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$K3S_CHANNEL sh -
sudo chown $(whoami):$(id -gn) ~/.kube/config