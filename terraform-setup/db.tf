resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mariadb"
  engine_version       = "10.6"
  instance_class       = var.db_instance_type
  db_name              = "k3s"
  username             = "rancher"
  password             = var.db_password
  #parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = ["${aws_security_group.sg_allowall.id}"]
}


