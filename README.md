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

## Benchmarks

To compile the benchmark JAR:

    mvn clean compile assembly:single

To run the benchmark:

    java -jar target/fdb-benchmarks-1.0-SNAPSHOT-jar-with-dependencies.jar -b SYSTEM -c ADDRESS -d DURATION -i INTERVAL -r READ_PERCENTAGE -o OPS

SYSTEM is VoltDB (volt) or FoundationDB (fdb).

ADDRESS is the address of the VoltDB server (not needed for FDB).

DURATION is the runtime of the benchmark.

INTERVAL is the length of time to wait between submitting queries (in microseconds, so an interval of 1000 submits 1K TPS).

READ_PERCENTAGE is the percentage of transactions that are read-only.

OPS is the number of operations (single-key reads or writes) to do per transaction.

Both VoltDB and FoundationDB clients are backed by a single network thread, so we found that fully saturating a single-core VoltDB or FDB database requires many (we used 8) concurrent client processes.

To run many FDB clients in parallel, use:

```shell
    scripts/run_parallel.sh -d DURATION -i INTERVAL -r READ_PERCENTAGE -o OPS -n NUM_CLIENTS
```