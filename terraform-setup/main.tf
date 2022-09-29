resource "aws_key_pair" "ssh_key_pair" {
  key_name_prefix = "${var.prefix}-rancher-k3s-sql"
  public_key      = file("${var.ssh_key_file_name}.pub")
}

# Security group to allow all traffic
resource "aws_security_group" "sg_allowall" {
  name        = "${var.prefix}-rancher-k3s-sql-allowall"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
	ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "rancher" {
  count         = var.rancher_node_count
  ami           = data.aws_ami.suse.id
  instance_type = "t3a.medium"

  key_name        = aws_key_pair.ssh_key_pair.key_name
  security_groups = [aws_security_group.sg_allowall.name]

  root_block_device {
    volume_size = 80
  }

  tags = {
    Use = "${var.prefix}-rancher-k3s-sql"
  }
}

resource "aws_instance" "downstreams" {
  count         = var.downstream_count
  ami           = data.aws_ami.suse.id
  instance_type = "t3a.medium"

  key_name        = aws_key_pair.ssh_key_pair.key_name
  security_groups = [aws_security_group.sg_allowall.name]

  root_block_device {
    volume_size = 80
  }

  tags = {
    Use = "${var.prefix}-rancher-k3s-downstream"
  }
}
