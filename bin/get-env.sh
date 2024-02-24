#!/usr/bin/env bash
TF_STATE="opentofu-setup/terraform.tfstate"

$(tofu output -state=$TF_STATE -json rancher_cluster_ips | jq -r 'keys[] as $k | "export IP\($k)=\(.[$k])"')

DIP=($(tofu output -state=$TF_STATE -json downstream_ips | jq -r '.[]'))

export RDS_PRE="mysql://$(tofu output -state=$TF_STATE --raw sql_user):"
export RDS_POST="@tcp($(tofu output -state=$TF_STATE --raw rds_endpoint))/\
$(tofu output -state=$TF_STATE --raw dbname)"

export URL="$(tofu output -state=$TF_STATE --raw url )"
