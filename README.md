# terraform-rancher
Install Rancher Using Terraform

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
