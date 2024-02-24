resource "aws_elb" "rancher-server-lb" {
  name               = "${var.prefix}-rancher-server-lb"
  availability_zones = aws_instance.rancher[*].availability_zone

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = [
	for instance in aws_instance.rancher : instance.id
  ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.prefix}-rancher-server-lb"
  }
}

resource "aws_route53_record" "rancher" {
  zone_id = data.aws_route53_zone.rancher.zone_id
  name    = "${var.rancher_url}.${data.aws_route53_zone.rancher.name}"
  type    = "CNAME"
  ttl     = "5"

  records        = ["${aws_elb.rancher-server-lb.dns_name}."]
}