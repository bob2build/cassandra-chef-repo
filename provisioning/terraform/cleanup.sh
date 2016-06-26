#!/bin/bash -l
set -v

knife node delete cassandra_cluster_node_1 -y
knife node delete cassandra_cluster_node_2 -y
knife node delete cassandra_cluster_node_3 -y
knife node delete cassandra_solo -y
knife node delete cassandra_opscenter -y
knife client delete cassandra_cluster_node_1 -y
knife client delete cassandra_cluster_node_2 -y
knife client delete cassandra_cluster_node_3 -y
knife client delete cassandra_solo -y
knife client delete cassandra_opscenter -y
