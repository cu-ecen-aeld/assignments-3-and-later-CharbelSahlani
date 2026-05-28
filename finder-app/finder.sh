#!/bin/sh
# Script to find the number of matching strings in a given directory
# Author: Charbel Al Sahlani


# Exit if no argument provided
if [ -z "$1" ]; then
    echo "Error: No path provided." >&2
    exit 1
fi

# Exit if 2nd argument not provided
if [ -z "$2" ]; then
    echo "Error: No string provided." >&2
    exit 1
fi

# Getting arguments from input after passing the arguments' checks
filesdir="$1"
searchstr="$2"

# Validate path existence
if [ ! -e "$filesdir" ]; then
    echo "Error: Path '$filesdir' does not exist." >&2
    exit 1
fi

# Get the number of files inside this directory
x=$(find "$filesdir" -type f | wc -l)
# Get the number of lines that include the input string inside the directory
y=$(grep -roh "$searchstr" "$filesdir" | wc -l)

# Output results
echo "The number of files are "$x" and the number of matching lines are "$y""

exit 0