variable "chef_server_url" {
  default = "https://api.chef.io/organizations/printfbabu"
}

variable "chef_validator_name" {
  default = "printfbabu-validator"
}

variable "chef_validator_pem" {
  default = "~/.chef/printfbabu-validator.pem"
}
