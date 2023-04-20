#!/bin/bash

# Check if an input parameter is provided and is a number
if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <number_of_nodes>"
  exit 1
fi

# Set the instance names and zone
instance_prefix="fdb-"
zone="us-central1-c"

# Get the coordinator's instance name
coordinator_instance_name="${instance_prefix}1"

# Get the number of nodes in the cluster as an input parameter
num_nodes="$1"

gcloud compute scp ${coordinator_instance_name}:/etc/foundationdb/fdb.cluster fdb.cluster --zone $zone

# Iterate through the instances and copy the fdb.cluster file to each instance
for ((i=2; i<=$num_nodes; i++)); do
  instance_name="${instance_prefix}${i}"
  echo "Copying fdb.cluster to $instance_name"
  gcloud compute scp fdb.cluster ${instance_name}:/tmp/fdb.cluster --zone $zone
  echo "Moving fdb.cluster to the correct location on $instance_name"
  gcloud compute ssh ${instance_name} --zone $zone --command "sudo mv /tmp/fdb.cluster /etc/foundationdb/fdb.cluster"
  gcloud compute ssh ${instance_name} --zone $zone --command "sudo service foundationdb restart"
done
