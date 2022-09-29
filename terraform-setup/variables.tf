variable "aws_access_key_id" {
  type        = string
  description = "AWS access key used to create infrastructure"
}
variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}
variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
  default     = "us-east-1"
}
variable "ssh_key_file_name" {
  type        = string
  description = "File path and name of SSH private key used for infrastructure and RKE"
  default     = "~/.ssh/id_rsa"
}
variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "mak3r"
}

variable "db_instance_type" {
  type = string
  description = "The aws model name for the rds instance"
  default = "db.t2.micro"
}

variable "rancher_url" {
	type = string
	description = "The subdomain for this rancher installation"
	default = "rancher-demo"
}

variable "db_password" {
	type = string
	description = "The rds db password"
	default = "adlkj^k1Kp9.432Xxn-z21"
}

variable "domain" {
	type = string
	description = "The domain to attach this rancher url onto"
	default = "mak3r.design."
}

variable "downstream_count" {
	type = number
	description = "The number of downstream instances to create"
	default = 0
}

variable "rancher_node_count" {
	type = number
	description = "The number of nodes to use for the rancher cluster"
	default = 1
}