

output "url" {
  value = "${var.rancher_url}.${data.aws_route53_zone.rancher.name}"
}
output "rancher_cluster_ips" {
  value = [
	for instance in aws_instance.rancher : instance.public_ip
  ]
}

output "downstream_ips" {
	value = aws_instance.downstreams.*.public_ip
}

output "downstream_count" {
	value = var.downstream_count
}

output "rds_endpoint" {
  value = try("${aws_db_instance.default[0].endpoint}", "none")
}

output "sql_user" {
  value = try("${aws_db_instance.default[0].username}", "none")
}

output "dbname" {
  value = try("${aws_db_instance.default[0].db_name}", "none")
}
