data "aws_ami" "suse" {
  most_recent = true
  owners      = ["679593333241"] # aws-marketplace

  filter {
    name   = "name"
    values = ["openSUSE-Leap-15.4-HVM-x86_64-22c5c717-9ac5-4721-8c69-2ec8bfdaf26b"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_route53_zone" "rancher" {
  name = "${var.domain}"
  private_zone = false
}

