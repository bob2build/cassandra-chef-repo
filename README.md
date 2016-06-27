# Cassandra with Chef/Terraform

## Overview
This repo contains necessary code to provision an cassandra cluster. Chef is used for configuration management and Terraform is used for provisioning AWS instances.

This repository demonstrates the following activities

* Create a 3 node cluster and 1 node cluster
* Create a opscenter server
* Load sample data into 3 node cluster
* Take snapshot of sample data from the 3 node cluster
* Restore snapshot from 3 node cluster in 1 node cluster

## Usage

### Prerequisites
* ChefDK setup
* ChefServer configuration

### Install
**NOTE: The following commands provision instances from AWS which may cost you money**

#### Create Chef artifacts

Cassandra and opscenter can be installed from [cassandra cookbook](https://github.com/michaelklishin/cassandra-chef-cookbook). The following roles jsons are created
* cassandra_cluster -> Role for nodes in 3 node cluster
* cassandra_solo -> Role for node in 1 node cluster
* opscenter_server -> Role for node used to install opscenter

The following commands would create roles/cookbooks in the chef server from the json file and Berksfile

```
gem install bundler
bundle install
knife role from file roles/cassandra_cluster.json
knife role from file roles/cassandra_solo.json
knife role from file roles/opscenter_server.json
berks install
berks upload
```

#### Provision the hosts

Terraform is used to describe the infrastructure. The resources are created in specific order to ensure that cluster is properly formed
* opscenter_server
* nodes of each cluster 1 node at a time.

Each node part of cluster needs to be configured with the opscenter server. Hence opscenter server is created first. The first node of a cluster forms the initial seed. Hence nodes coming up later, should be able to contact the seed node. Hence nodes are created 1 at a time. The following commands will provision the nodes. It also creates the required security groups and keypairs.

```
cd provisioning/terraform
ssh-keygen -f data/cassandra.pem -P "" # Generates Keypair
terraform get
terraform plan # Just to preview what changes are to be applied
terraform apply
```

#### Loading data into the three node cluster
YCMA, a benchmark tool for nosql dbs can be used to load sample data. Since the instances we launch are behind VPC NAT, It is better to run the loader by sshing into any of the cluster nodes or even opscenter

SSH to any of the node using cassandra key that was generated in the previous steps
```
ssh -i data/cassandra.pem ec2-user@<<hostname>>
```

Install git and maven in the nodes. All the nodes come java as part of cassandra installation.
```
sudo yum install git
wget http://redrockdigimark.com/apachemirror/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar xzvf apache-maven-3.3.9-bin.tar.gz
sudo mkdir /opt/maven
sudo mv apache-maven-3.3.9 /opt/maven/.
export PATH=$PATH:/opt/maven/apache-maven-3.3.9/bin
```

Create the schema
```
cqlsh
cqlsh> create keyspace ycsb
    WITH REPLICATION = {'class' : 'SimpleStrategy', 'replication_factor': 3 };
cqlsh> use ycsb;
cqlsh:ycsb> create table usertable (
    y_id varchar primary key,
    field0 varchar,
    field1 varchar,
    field2 varchar,
    field3 varchar,
    field4 varchar,
    field5 varchar,
    field6 varchar,
    field7 varchar,
    field8 varchar,
    field9 varchar);
cqlsh> quit;
```

Load sample generated data into table. Note, workload can be tweaked to achieve required data size from workload/workload* files
```
git clone https://github.com/brianfrankcooper/YCSB.git
cd YCSB
./bin/ycsb load cassandra2-cql -P workloads/workloada -p hosts=<<any node part of 3 node cluster>>
cqlsh
cqlsh> use ycsb;
cqlsh:ycsb> select count(*) from usertable;
count
-------
 1000
(1 rows)
cqlsh:ycsb> quit;
```

Backuping up cassandra is rather simple. We need to run the nodetool snapshot command in each of the node.

Use pssh or any other ssh utilities to run the following command on all nodes
```
nodetool snapshot -t migration ycsb
```
This would create snapshots of keyspace ycsb at /var/lib/cassandra/data/ycsb/usertable-\*/snapshots/migration/

Sample setup and execution using PSSH
Create ~/.ssh/config file with the following content
```
Host cassandra_solo
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  HostName ec2-52-41-157-119.us-west-2.compute.amazonaws.com
  IdentityFile ~/.secrets/sshkeys/cassandra.pem
Host cassandra_1
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  HostName ec2-52-34-113-96.us-west-2.compute.amazonaws.com
  IdentityFile ~/.secrets/sshkeys/cassandra.pem
Host cassandra_2
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  HostName ec2-52-33-146-143.us-west-2.compute.amazonaws.com
  IdentityFile ~/.secrets/sshkeys/cassandra.pem
Host cassandra_3
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  HostName ec2-52-32-54-40.us-west-2.compute.amazonaws.com
  IdentityFile ~/.secrets/sshkeys/cassandra.pem
Host opscenter
  User ec2-user
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  HostName ec2-52-25-69-0.us-west-2.compute.amazonaws.com
  IdentityFile ~/.secrets/sshkeys/cassandra.pem
```

Change the hostnames and identity files as needed. Create a cluster_hosts.txt file which contains
```
cassandra_1
cassandra_2
cassandra_3
```

Install PSSH
```
sudo yum install python-pip
sudo pip install pssh
```

Run backup on all nodes of the cluster

```
pssh -h cluster_hosts.txt -i "nodetool snapshot -t migration ycsb; tar cvf migration.tar.gz /var/lib/cassandra/data/ycsb/usertable-*/snapshots/migration"
pslurp -h cluster_hosts.txt /home/ec2-user/migration.tar.gz .
```
The file will be downloaded to cassandr_1/migration.tar.gz, cassandr_3/migration.tar.gz, cassandr_3/migration.tar.gz

To clear backup folders
```
pssh -h cluster_hosts.txt -i "nodetool -h localhost -p 7199 clearsnapshot"
```

Retrieve the tokens from the cluster by doing ssh on to the machine
```
ssh cassandra_1
IPADDR=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`; nodetool ring | grep $IPADDR | awk '{print $NF ","}' | xargs
ssh cassandra_2
IPADDR=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`; nodetool ring | grep $IPADDR | awk '{print $NF ","}' | xargs
ssh cassandra_3
IPADDR=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`; nodetool ring | grep $IPADDR | awk '{print $NF ","}' | xargs
```

## TODO
* Restore cassandra data to single Node cluster
