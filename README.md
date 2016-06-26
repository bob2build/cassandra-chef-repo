# Cassandra with Chef/Terraform

## Overview
This repo contains necessary code to provision an cassandra cluster. Chef is used for configuration management and Terraform is used for provisioning AWS instances.


## Usage

### Prerequisites
* ChefDK setup
* ChefServer configuration

### Install
**NOTE: The following commands provision instances from AWS which may cost you money**
```
gem install bundler
bundle install
knife role from file roles/cassandra_cluster.json
knife role from file roles/cassandra_solo.json
knife role from file roles/opscenter_server.json
berks install
berks upload
cd provisioning/terraform
ssh-keygen -f data/cassandra.pem -P ""
terraform get
terraform plan # Just to preview what changes are to be applied
terraform apply
```

## TODO
* Add support for creating sample schema and uploading data
* Backup cassandra data
* Restore cassandra data
