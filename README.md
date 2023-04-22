# fdb-benchmarks

Requires Java 11 and Maven.

## FoundationDB

To install FoundationDB, follow the directions here:

    https://apple.github.io/foundationdb/getting-started-linux.html

To make an FDB server accessible to remote clients, run:

    sudo python3 /usr/lib/foundationdb/make_public.py

To access FDB from a remote client, copy the server's fdb.cluster file (/etc/foundationdb/fdb.cluster) into the repository root directory.

We pinned all FDB processes to a single core using taskset (taskset -cp 0 PID).

## VoltDB

To install VoltDB, clone and build the repository:

    https://github.com/VoltDB/voltdb

Set the VOLT_HOME environment variable to Volt's root directory and add VoltDB binaries to your path.  Then, initialize VoltDB:

    scripts/initialize_voltdb.sh

## FoundationDB Benchmark

Deploy the cluster:

```shell
cd terraform
terraform init
terraform apply
./copy_fdb_cluster.sh NUM_MACHINES
```

First, initialize the data:

```shell
java -jar target/fdb-benchmarks-1.0-SNAPSHOT-jar-with-dependencies.jar -b fdb-init -k NUM_KEYS
```

Then, to run many FDB clients in parallel, use:

```shell
scripts/run_parallel.sh -d DURATION -i INTERVAL -r READ_PERCENTAGE -o OPS -k NUM_KEYS -n NUM_CLIENTS
```