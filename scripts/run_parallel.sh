#!/bin/bash

# Check if the required number of arguments is provided
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 DURATION INTERVAL READ_PERCENTAGE OPS NUM_CLIENTS"
  exit 1
fi

# Define the command you want to run
cmd=(java -jar target/fdb-benchmarks-1.0-SNAPSHOT-jar-with-dependencies.jar -b fdb -d $1 -i $2 -r $3 -o $4)

# Number of parallel clients
num_clients=$5

# Output file where the results will be concatenated
output_file="output.txt"

# Remove the output file if it already exists to start fresh
rm -f "${output_file}"

# Run the command multiple times in separate processes and concatenate outputs
for i in $(seq "${num_clients}"); do
  ( "${cmd[@]}" >> "${output_file}" ) &
done

# Wait for all processes to complete before exiting the script
wait