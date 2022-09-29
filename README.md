# terraform-rancher
Install Rancher Using Terraform

## IMPORTANT
The backup target makes a local copy of the k3s server directory. **Do not commit this to git as it contains the keys to your Rancher kubernetes installation.**

## Dependencies

* terraform
* helm
* jq
* kubectl
* aws
* dns address for Rancher

## Quick Start

### Prep
* `cp terraform-setup/terraform.tfvars.template terraform-setup/terraform.tfvars`
    * Adjust the tfvars variables as desired
* Set your aws account id and key using the terraform variables
    * `aws_access_key_id`
    * `aws_secret_access_key`
* See `variables.tf` for other infrastructure configuration 
* Make sure you have a registered domain
    * Use terraform variable `domain` to set it
    * Use terraform variable `rancher_url` to set the subdomain
    * fqdn is <rancher_url>.<domain>

1. `make rancher` Only do this once if you are keeping backups.
1. `make backup_rancher` Backup to the `backup` directory
1. `make restore_rancher` Restore the rancher installation from the `backup` directory

## Make targets

* `infrastructure` - build the infrastructure needed to host k3s and Rancher
* `k3s_sql_install` - use k3s backed by an RDS sql datastore
    * use parameter `RANCHER_NODE_COUNT=2` for a 2 node HA backend
    * HA capable
* `k3s_install` - use k3s with the default embedded sqlite datastore. 
    * Single node only
    * Not HA
    * Local (workstation) backup and restore
* `rancher` - make the infrastructure and install the sqlite version of k3s and also Rancher
* `backup_rancher` - backup the currently installed sqlite k3s version
* `restore_rancher` - restore the previously installed sqlite k3s version from a local copy
* `destroy` - destroy the infrastructure 
* `install_kubeconfig` - run after `k3s_install` target. **WARNING** THIS WILL OVERWRITE YOUR LOCAL `.kube/config`
* `backup_kubeconfig` - backup your local `.kube/config` before overwriting it with `install_kubeconfig`

## Restoring the Rancher Cluster

Follow the quickstart steps to create, backup and restore rancher. Once the Rancher cluster is created it can be backed up or destroyed. If it is backed up, you can restore it using `make restore_rancher`. The `restore_rancher` target assumes that the backup exists and that the infrastructure has been `destroy`ed. 


Restoration may take some time even after the make process ends as kubernetes must right itself by downloading and installing resources that are backedup in the datastore. Follow the post restore steps that make prints out to complete the restore process.