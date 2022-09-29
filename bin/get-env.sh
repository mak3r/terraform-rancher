#!/usr/bin/env bash
TF_STATE="terraform-setup/terraform.tfstate"

$(terraform output -state=$TF_STATE -json rancher_cluster_ips | jq -r 'keys[] as $k | "export IP\($k)=\(.[$k])"')

DIP=($(terraform output -state=$TF_STATE -json downstream_ips | jq -r '.[]'))

export RDS_PRE="mysql://$(terraform output -state=$TF_STATE --raw sql_user):"
export RDS_POST="@tcp($(terraform output -state=$TF_STATE --raw rds_endpoint))/\
$(terraform output -state=$TF_STATE --raw dbname)"

export URL="$(terraform output -state=$TF_STATE --raw url )"
