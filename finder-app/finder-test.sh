#!/bin/sh
# Tester script for assignment 1 and assignment 2
# Modified to use C writer application
# Author: Siddhant Jajoo, modified by Paolo Veronesi

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data
username=$(cat conf/username.txt)

# Handle command line arguments
if [ $# -lt 3 ]
then
    echo "Using default value ${WRITESTR} for string to write"
    if [ $# -lt 1 ]
    then
        echo "Using default value ${NUMFILES} for number of files to write"
    else
        NUMFILES=$1
    fi 
else
    NUMFILES=$1
    WRITESTR=$2
    WRITEDIR=/tmp/aeld-data/$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"

# Remove old files
rm -rf "${WRITEDIR}"

# Create write directory if not assignment1
assignment=$(cat ../conf/assignment.txt)

if [ "$assignment" != 'assignment1' ]
then
    mkdir -p "$WRITEDIR"
    if [ -d "$WRITEDIR" ]
    then
        echo "$WRITEDIR created"
    else
        exit 1
    fi
fi

# --------------------------
# Clean previous build and compile writer C application
# --------------------------
#make clean
#make

# Write files using C writer
for i in $(seq 1 $NUMFILES)
do
    ./writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
done

# Run finder script
OUTPUTSTRING=$(./finder.sh "$WRITEDIR" "$WRITESTR")

# Remove temporary directories
rm -rf /tmp/aeld-data

# Verify output
set +e
echo ${OUTPUTSTRING} | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
    echo "success"
    exit 0
else
    echo "failed: expected ${MATCHSTR} in ${OUTPUTSTRING} but instead found"
    exit 1
fi