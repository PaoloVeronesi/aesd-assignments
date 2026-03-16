#!/bin/bash

# Check for exactly 2 arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <directory> <search-string>"
    exit 1
fi

directory=$1
searchstr=$2

if [ ! -d "$directory" ]; then
    echo "Error: $directory is not a directory"
    exit 1
fi

num_files=$(find "$directory" -type f | wc -l)
num_matches=$(grep -r "$searchstr" "$directory" | wc -l)


echo "The number of files are $num_files and the number of matching lines are $num_matches"