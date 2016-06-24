variable "sshkey_name" {
  type = "string"
}

variable "sshkey_pem" {
  type = "string"
}

variable "security_groups" {
  type = "string"
}

variable "chef_role" {
  type = "string"
}

variable "chef_node" {
  type = "string"
}

variable "chef_server_url" {
  type = "string"
}

variable "chef_validator_name" {
  type = "string"
}

variable "chef_validator_pem" {
  type = "string"
}

# Dummy variable to introduce dependencies between modules
variable "wait_for" {
  type = "string"
  default = "self"
}
