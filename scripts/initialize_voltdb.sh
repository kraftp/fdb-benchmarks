#!/bin/bash
set -ex

SCRIPT_DIR=$(dirname $(readlink -f $0))
# Enter the root dir of the repo.
cd ${SCRIPT_DIR}/../

VOLTDB_BIN="${VOLT_HOME}/bin"

# Create obj directory
rm -rf obj
mkdir -p obj/sql

voltdb init -f --dir=/var/tmp --config ${SCRIPT_DIR}/local_config.xml
taskset -c 0 voltdb start -B --ignore=thp --dir=/var/tmp

# Wait until VoltDB is ready.
MAX_TRY=30
cnt=0
while [[ -z "${ready}" ]]; do
  python2 ${VOLTDB_BIN}/voltadmin status 2>&1 | grep -q "live host" && ready="ready"
  cnt=$[$cnt+1]
  if [[ $cnt -eq ${MAX_TRY} ]]; then
    echo "Wait timed out. VoltDB failed to start."
    exit 1
  fi
  sleep 5 # avoid busy loop
done

# Create tables.
sqlcmd < sql/create_benchmark_tables.sql

# Create obj and target directory
mkdir -p obj/
mkdir -p target/

# Compile stored procedures.
javac -cp "$VOLT_HOME/voltdb/*:$PWD/target/*" -d obj/sql $(find sql/ -type f -name *.java)
jar cvf target/DBOSProcedures.jar -C obj/sql .
sqlcmd < sql/load_procedures.sql