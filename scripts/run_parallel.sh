#!/bin/bash

# Define usage function
usage() {
  echo "Usage: $0 -d DURATION -i INTERVAL -r READ_PERCENTAGE -o OPS -k NUM_KEYS -n NUM_CLIENTS"
  exit 1
}

# Process command-line options using getopts
while getopts "d:i:r:o:k:n:" opt; do
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
    k)
      NUM_KEYS="$OPTARG"
      ;;
    *)
      usage
      ;;
  esac
done

# Verify that all required options are provided
if [ -z "${DURATION}" ] || [ -z "${INTERVAL}" ] || [ -z "${READ_PERCENTAGE}" ] || [ -z "${OPS}" ] || [ -z "${NUM_KEYS}" ] || [ -z "${NUM_CLIENTS}" ]; then
  usage
fi

# Define the command you want to run
cmd=(java -jar target/fdb-benchmarks-1.0-SNAPSHOT-jar-with-dependencies.jar -b fdb -d "${DURATION}" -i "${INTERVAL}" -r "${READ_PERCENTAGE}" -o "${OPS}" -k "${NUM_KEYS}")

# Run the command multiple times in separate processes and concatenate outputs
for i in $(seq "${NUM_CLIENTS}"); do
  ( "${cmd[@]}" ) &
done

# Wait for all processes to complete before exiting the script
wait