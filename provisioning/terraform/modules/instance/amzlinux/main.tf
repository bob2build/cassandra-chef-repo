resource "aws_instance" "cassandra" {
  instance_type = "t2.micro"
  ami = "ami-f303fb93"
  key_name = "${var.sshkey_name}"
  security_groups = ["${split(",", var.security_groups)}"]

  provisioner "chef"  {
    connection {
      user = "ec2-user"
      private_key = "${file(var.sshkey_pem)}"
    }

    attributes_json = <<EOF
    {
    }
    EOF
    environment = "_default"
    run_list = ["role[${var.chef_role}]"]
    node_name = "${var.chef_node}"
    server_url = "${var.chef_server_url}"
    validation_client_name = "${var.chef_validator_name}"
    validation_key = "${file(var.chef_validator_pem)}"
    version = "12.0.1"
  }
}

output "instance_ip" {
  value = "${aws_instance.cassandra.public_ip}"
}
