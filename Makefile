SHELL := /bin/bash
K3S_TOKEN="mak3rVA87qPxet2SB8BDuLPWfU2xnPUSoETYF"
RANCHER_VERSION="2.7.4"
SERVER_NUM=-1
ADMIN_SECRET="6DfOqQMzaNFTg6VV"
K3S_CHANNEL=v1.25
K3S_UPGRADE_CHANNEL=v1.26
RANCHER_SUBDOMAIN=tf-rancher
SQL_PASSWORD="Kw309ii9mZpqD"
export KUBECONFIG=kubeconfig
BACKUP_NAME=kubeconfig.tf_rancher
API_TOKEN="abcdef:EXAMPLEtokenGoesHere"
DOWNSTREAM_COUNT=0
RANCHER_NODE_COUNT=1
BACKUP_LOCATION="backup"
LETS_ENCRYPT_USER="user@email.org"

.PHONY: destroy
destroy:
	-rm kubeconfig
	cd terraform-setup && terraform destroy -auto-approve && rm terraform.tfstate terraform.tfstate.backup

.PHONY: rancher
rancher: infrastructure k3s_install rancher_app

.PHONY: infrastructure
infrastructure:
	echo "Creating infrastructure"
	cd terraform-setup && terraform init && terraform apply -auto-approve -var rancher_url=$(RANCHER_SUBDOMAIN) -var db_password=$(SQL_PASSWORD) -var downstream_count=$(DOWNSTREAM_COUNT) -var rancher_node_count=$(RANCHER_NODE_COUNT)

.PHONY: k3s_sql_install
k3s_sql_install: 
	echo "Creating k3s cluster"
	source bin/get-env.sh && [[ ! -n "$${IP1}" ]] && echo "Cluster will be single node" || "Cluster will be multi-node"
	source bin/get-env.sh && ssh -o StrictHostKeyChecking=no ec2-user@$${IP0} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server --tls-san $${IP0} ' K3S_DATASTORE_ENDPOINT='$${RDS_PRE}$(SQL_PASSWORD)$${RDS_POST}' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 sh -"
	source bin/get-env.sh && [[ -z "$${IP1}" ]] && echo "no additional servers to join cluster" || ssh -o StrictHostKeyChecking=no ec2-user@$${IP1} "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$(K3S_CHANNEL) INSTALL_K3S_EXEC='server --tls-san $${IP0} --tls-san $${IP1}' K3S_DATASTORE_ENDPOINT='$${RDS_PRE}$(SQL_PASSWORD)$${RDS_POST}' K3S_TOKEN=$(K3S_TOKEN) K3S_KUBECONFIG_MODE=644 sh -"
	source bin/get-env.sh && scp -o StrictHostKeyChecking=no ec2-user@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source bin/get-env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig

.PHONY: k3s_install
k3s_install:
	echo "Creating k3s cluster"
	source bin/get-env.sh && ssh -o StrictHostKeyChecking=no ec2-user@$${IP0} '/bin/bash -s' -- < bin/install-k3s.sh "$(K3S_CHANNEL)" "$${IP0}"
	source bin/get-env.sh && scp -o StrictHostKeyChecking=no ec2-user@$${IP0}:/etc/rancher/k3s/k3s.yaml kubeconfig
	source bin/get-env.sh && sed -i '' "s/127.0.0.1/$${IP0}/g" kubeconfig

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
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
	helm repo update
	helm upgrade --install \
		  cert-manager jetstack/cert-manager \
		  --namespace cert-manager \
		  --version v1.9.1 \
		  --create-namespace 
	kubectl rollout status deployment -n cert-manager cert-manager
	kubectl rollout status deployment -n cert-manager cert-manager-webhook
	source bin/get-env.sh && helm upgrade --install rancher rancher-latest/rancher \
	  --namespace cattle-system \
	  --version ${RANCHER_VERSION} \
	  --set hostname=$${URL} \
	  --set bootstrapPassword=${ADMIN_SECRET} \
	  --set replicas=1 \
	  --set ingress.tls.source=letsEncrypt \
	  --set letsEncrypt.email=${LETS_ENCRYPT_USER} \
	  --set letsEncrypt.ingress.class=traefik \
	  --set global.cattle.psp.enabled=false \
	  --create-namespace 
	kubectl rollout status deployment -n cattle-system rancher
	kubectl -n cattle-system wait --for=condition=ready certificate/tls-rancher-ingress
	@echo
	@echo
	@source bin/get-env.sh && echo https://$${URL}/dashboard/?setup=${ADMIN_SECRET}

.PHONY: backup_rancher
backup_rancher:
	mkdir -p ${BACKUP_LOCATION}
	kubectl get node -o=jsonpath='{.items[0].metadata.name}' > ${BACKUP_LOCATION}/node-name
	source bin/get-env.sh && bin/backup-rancher.sh $${IP0} ${BACKUP_LOCATION}

.PHONY: restore_rancher
restore_rancher: infrastructure copy_to_remote k3s_install manual_steps

.PHONY: copy_to_remote
copy_to_remote:
	source bin/get-env.sh && bin/restore-rancher.sh $${IP0} ${BACKUP_LOCATION}

.PHONY: manual_steps
manual_steps:
	@echo
	@echo
	@echo "There is more to do .."
	@echo "1. make install_kubeconfig"
	@printf "2. Login to Rancher again.  "
	@source bin/get-env.sh && echo https://$${URL}/dashboard/

.PHONY: list_restores
list_restores:
	@for d in `ls backup`;do echo "backup/$${d}"; done

.PHONY: info
info:
	cd terraform-setup && terraform output