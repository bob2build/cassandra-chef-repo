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

resource "aws_instance" "cassandra_cluster_node_1" {
  instance_type = "t2.micro"
  ami = "ami-f303fb93"
  key_name = "cassandra"
  security_groups = ["${aws_security_group.cassandra.name}"]

  provisioner "chef"  {
    connection {
      user = "ec2-user"
      private_key = "${file("./data/cassandra.pem")}"
    }

    attributes_json = <<EOF
    {
    }
    EOF
    environment = "_default"
    run_list = ["role[cassandra_cluster]"]
    node_name = "cassandra_cluster_node_1"
    server_url = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key = "${file(var.chef_validator_pem)}"
    version = "12.0.1"
  }
}

resource "aws_instance" "cassandra_cluster_node_2" {
  depends_on = ["aws_instance.cassandra_cluster_node_1"]
  instance_type = "t2.micro"
  ami = "ami-f303fb93"
  key_name = "cassandra"
  security_groups = ["${aws_security_group.cassandra.name}"]

  provisioner "chef"  {
    connection {
      user = "ec2-user"
      private_key = "${file("./data/cassandra.pem")}"
    }

    attributes_json = <<EOF
    {
    }
    EOF
    environment = "_default"
    run_list = ["role[cassandra_cluster]"]
    node_name = "cassandra_cluster_node_2"
    server_url = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key = "${file(var.chef_validator_pem)}"
    version = "12.0.1"
  }
}

resource "aws_instance" "cassandra_cluster_node_3" {
  depends_on = ["aws_instance.cassandra_cluster_node_2"]
  instance_type = "t2.micro"
  ami = "ami-f303fb93"
  key_name = "cassandra"
  security_groups = ["${aws_security_group.cassandra.name}"]

  provisioner "chef"  {
    connection {
      user = "ec2-user"
      private_key = "${file("./data/cassandra.pem")}"
    }

    attributes_json = <<EOF
    {
    }
    EOF
    environment = "_default"
    run_list = ["role[cassandra_cluster]"]
    node_name = "cassandra_cluster_node_3"
    server_url = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key = "${file(var.chef_validator_pem)}"
    version = "12.0.1"
  }
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
