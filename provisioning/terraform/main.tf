provider "aws" {
  region = "us-west-2"
}

resource "aws_key_pair" "cassandra" {
  key_name = "cassandra"
  public_key = "${file("./data/cassandra.pem.pub")}"
}

resource "aws_security_group" "cassandra" {
  name        = "cassandra"
  description = "Security group for cassandra server"

  # Unrestricted access from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "cluster_node_1" {
  source = "./modules/instance/amzlinux"
  sshkey_name = "cassandra"
  security_groups = "${aws_security_group.cassandra.name}"
  sshkey_pem = "./data/cassandra.pem"
  sshkey_name = "cassandra"
  chef_role = "cassandra_cluster"
  chef_node = "cassandra_cluster_node_1"
  chef_server_url = "${var.chef_server_url}"
  chef_validator_name = "${var.chef_validator_name}"
  chef_validator_pem = "${var.chef_validator_pem}"
  wait_for = "self"
}

module "cluster_node_2" {
  source = "./modules/instance/amzlinux"
  sshkey_name = "cassandra"
  security_groups = "${aws_security_group.cassandra.name}"
  sshkey_pem = "./data/cassandra.pem"
  sshkey_name = "cassandra"
  chef_role = "cassandra_cluster"
  chef_node = "cassandra_cluster_node_2"
  chef_server_url = "${var.chef_server_url}"
  chef_validator_name = "${var.chef_validator_name}"
  chef_validator_pem = "${var.chef_validator_pem}"
  wait_for = "${module.cluster_node_1.instance_ip}"
}

module "cluster_node_3" {
  source = "./modules/instance/amzlinux"
  sshkey_name = "cassandra"
  security_groups = "${aws_security_group.cassandra.name}"
  sshkey_pem = "./data/cassandra.pem"
  sshkey_name = "cassandra"
  chef_role = "cassandra_cluster"
  chef_node = "cassandra_cluster_node_3"
  chef_server_url = "${var.chef_server_url}"
  chef_validator_name = "${var.chef_validator_name}"
  chef_validator_pem = "${var.chef_validator_pem}"
  wait_for = "${module.cluster_node_2.instance_ip}"
}

module "cluster_solo" {
  source = "./modules/instance/amzlinux"
  sshkey_name = "cassandra"
  security_groups = "${aws_security_group.cassandra.name}"
  sshkey_pem = "./data/cassandra.pem"
  sshkey_name = "cassandra"
  chef_role = "cassandra_solo"
  chef_node = "cassandra_solo"
  chef_server_url = "${var.chef_server_url}"
  chef_validator_name = "${var.chef_validator_name}"
  chef_validator_pem = "${var.chef_validator_pem}"
}
