#!/bin/bash

# Define usage function
usage() {
  echo "Usage: $0 -d DURATION -i INTERVAL -r READ_PERCENTAGE -o OPS -n NUM_CLIENTS"
  exit 1
}

# Process command-line options using getopts
while getopts "d:i:r:o:n:" opt; do
  case $opt in
    d)
      DURATION="$OPTARG"
      ;;
    i)
      INTERVAL="$OPTARG"
      ;;
    r)
      READ_PERCENTAGE="$OPTARG"
      ;;
    o)
      OPS="$OPTARG"
      ;;
    n)
      NUM_CLIENTS="$OPTARG"
      ;;
    *)
      usage
      ;;
  esac
done

# Verify that all required options are provided
if [ -z "${DURATION}" ] || [ -z "${INTERVAL}" ] || [ -z "${READ_PERCENTAGE}" ] || [ -z "${OPS}" ] || [ -z "${NUM_CLIENTS}" ]; then
  usage
fi

# Define the command you want to run
cmd=(java -jar target/fdb-benchmarks-1.0-SNAPSHOT-jar-with-dependencies.jar -b fdb -d $1 -i $2 -r $3 -o $4)

# Run the command multiple times in separate processes and concatenate outputs
for i in $(seq "${NUM_CLIENTS}"); do
  ( "${cmd[@]}" ) &
done

# Wait for all processes to complete before exiting the script
wait