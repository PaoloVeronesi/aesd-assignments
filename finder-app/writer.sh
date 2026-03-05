#!/bin/bash

# Check for exactly 2 arguments
if [ $# -ne 2 ]; then
    echo "Error: Missing arguments. Usage: $0 <writefile> <writestr>"
    exit 1
fi

writefile=$1
writestr=$2

# Extract the parent directory
parentDir=$(dirname "$writefile")

# Create the directory path if it doesn't exist
if ! mkdir -p "$parentDir"; then
    echo "Error: Could not create directory path '$parentDir'"
    exit 1
fi

# Write the string to the file, overwriting if it exists
if ! echo "$writestr" > "$writefile"; then
    echo "Error: Could not create or write to file '$writefile'"
    exit 1
fi

# Optional: print success message
echo "File '$writefile' created with provided content."