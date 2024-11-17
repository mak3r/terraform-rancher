data "aws_ami" "suse" {
  most_recent = true
  owners      = ["679593333241"] # aws-marketplace

  #"ImageId": "ami-019aa0ac90f597bf5"
  filter {
    name   = "name"
    values = ["openSUSE-Leap-15.6-HVM-x86_64-prod-xkhy6u6pewna4"]
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

