SHELL := /bin/bash
K3S_TOKEN="mak3rVA87qPxet2SB8BDuLPWfU2xnPUSoETYF"
RKE2_TOKEN="mak3rVA87qPxet2SB8BDuLPWfU2xnPUSoETYF"
RANCHER_VERSION="2.9.2"
# rancher-latest | rancher-stable
HELM_RANCHER_REPO="rancher-latest"
TURTLES_VERSION="0.12.0"
CERT_MANAGER_VERSION="v1.12.7"
SERVER_NUM=-1
ADMIN_SECRET="demo"
K3S_CHANNEL=v1.29
RKE2_CHANNEL=v1.29
RANCHER_SUBDOMAIN=demo
SQL_PASSWORD="Kw309ii9mZpqD"
export KUBECONFIG=kubeconfig
BACKUP_NAME=kubeconfig.tf_rancher
API_TOKEN="abcdef:EXAMPLEtokenGoesHere"
DOWNSTREAM_COUNT=0
RANCHER_NODE_COUNT=1
# agentTLSMode parameter for Rancher Helm Options
# system-store | strict (default)
AGENT_TLS_MODE="system-store"
LETS_ENCRYPT_USER="user_at_email_dot_org"
# traefik (k3s) | nginx (rke2)
LETS_ENCRYPT_INGRESS_CLASS="nginx"

## NOTE ON DESTROY ISSUES ##
# If you have issues with the destroy command, you may need to add this parameter to the terraform destroy command:
# This allows deletion of an ami that no longer exists.
# Planning failed. OpenTofu encountered an error while generating this plan.
#
# ╷
# │ Error: Your query returned no results. Please change your search criteria and try again.
# │ 
# │   with data.aws_ami.suse,
# │   on data.tf line 1, in data "aws_ami" "suse":
# │    1: data "aws_ami" "suse" {
# │ 
# tofu destroy -auto-approve -refresh=false
##
.PHONY: destroy
destroy:
	-rm kubeconfig
	cd opentofu-setup && tofu destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

.PHONY: pause
pause: 
	sleep 60

.PHONY: rke2_rancher
rke2_rancher: infrastructure pause rke2_install pause rancher_app

.PHONY: k3s_rancher
k3s_rancher: infrastructure pause k3s_install pause rancher_app

.PHONY: infrastructure
infrastructure:
	echo "Creating infrastructure"
	cd opentofu-setup && tofu init && tofu apply -auto-approve -var rancher_url=$(RANCHER_SUBDOMAIN) -var db_password=$(SQL_PASSWORD) -var downstream_count=$(DOWNSTREAM_COUNT) -var rancher_node_count=$(RANCHER_NODE_COUNT)

.PHONY: k3s_sql_install
k3s_sql_install: 
	echo "Creating k3s cluster"
	source bin/get-env.sh && [[ ! -n "$${IP1}" ]] && echo "Cluster will be single node" || "Cluster will be multi-node"
	source bin/get-env.sh && ssh -o StrictHostKeyChecking=no ec2-user@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server --tls-san $${IP0} ' K3S_DATASTORE_ENDPOINT='$${RDS_PRE}$(SQL_PASSWORD)$${RDS_POST}' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 sh -"
	source bin/get-env.sh && [[ -z "$${IP1}" ]] && echo "no additional servers to join cluster" || ssh -o StrictHostKeyChecking=no ec2-user@$${IP1} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server --tls-san $${IP0} --tls-san $${IP1}' K3S_DATASTORE_ENDPOINT='$${RDS_PRE}$(SQL_PASSWORD)$${RDS_POST}' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 sh -"
	source bin/get-env.sh && scp -o StrictHostKeyChecking=no ec2-user@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source bin/get-env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig

.PHONY: k3s_install
# Be sure to update the ingress controller
#--set letsEncrypt.ingress.class=traefik
k3s_install:
	echo "Creating k3s cluster"
	source bin/get-env.sh && ssh -o StrictHostKeyChecking=no ec2-user@$${IP0} '/bin/bash -s' -- < bin/install-k3s.sh "$(K3S_CHANNEL)" "$${IP0}"
	source bin/get-env.sh && scp -o StrictHostKeyChecking=no ec2-user@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source bin/get-env.sh && sed -i'' "s/127.0.0.1/$${IP0}/g" kubeconfig

.PHONY: rke2_install
# Be sure to update the ingress controller
#--set letsEncrypt.ingress.class=nginx
rke2_install:
	echo "Creating rke2 cluster"
	source bin/get-env.sh && ssh -o StrictHostKeyChecking=no ec2-user@$${IP0} '/bin/bash -s' -- < bin/install-rke2.sh "$(RKE2_CHANNEL)" "$${IP0}"
	source bin/get-env.sh && scp -o StrictHostKeyChecking=no ec2-user@$${IP0}:/home/ec2-user/.kube/config kubeconfig
	source bin/get-env.sh && sed -i'' "s/127.0.0.1/$${IP0}/g" kubeconfig

.PHONY: backup_kubeconfig
backup_kubeconfig:
	cp ~/.kube/config ~/.kube/$(BACKUP_NAME)

.PHONY: install_kubeconfig
install_kubeconfig:
	cp ./kubeconfig ~/.kube/config

.PHONY: restore_kubeconfig
restore_kubeconfig:
	cp ~/.kube/$(BACKUP_NAME) ~/.kube/config

.PHONY: rancher_app
rancher_app: 
	echo "Installing cert-manager and Rancher"
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml
	helm repo add jetstack https://charts.jetstack.io
	helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
	helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
	helm repo update
	helm upgrade --install \
		  cert-manager jetstack/cert-manager \
		  --namespace cert-manager \
		  --version ${CERT_MANAGER_VERSION} \
		  --create-namespace 
	kubectl rollout status deployment -n cert-manager cert-manager
	kubectl rollout status deployment -n cert-manager cert-manager-webhook
	source bin/get-env.sh && helm upgrade --install rancher ${HELM_RANCHER_REPO}/rancher \
	  --namespace cattle-system \
	  --create-namespace \
	  --version ${RANCHER_VERSION} \
	  --set hostname=$${URL} \
	  --set bootstrapPassword=${ADMIN_SECRET} \
	  --set replicas=1 \
	  --set agentTLSMode=${AGENT_TLS_MODE} \
	  --set ingress.tls.source=letsEncrypt \
	  --set letsEncrypt.email=${LETS_ENCRYPT_USER} \
	  --set letsEncrypt.ingress.class=${LETS_ENCRYPT_INGRESS_CLASS} 
	kubectl rollout status deployment -n cattle-system rancher
	kubectl -n cattle-system wait --for=condition=ready certificate/tls-rancher-ingress
	@echo
	@echo
	@source bin/get-env.sh && echo https://$${URL}/dashboard/?setup=${ADMIN_SECRET}

# Rancher v2.9.2 has turtles automatically installed
.PHONY: turtles_install
turtles_install:
	helm repo add turtles https://rancher.github.io/turtles
	helm repo update
	helm upgrade --install rancher-turtles turtles/rancher-turtles \
    --version ${TURTLES_VERSION} \
    -n rancher-turtles-system \
    --dependency-update \
    --create-namespace --wait \
    --timeout 180s \
    --set cluster-api-operator.cert-manager.enabled=false


.PHONY: info
info:
	cd opentofu-setup && tofu output