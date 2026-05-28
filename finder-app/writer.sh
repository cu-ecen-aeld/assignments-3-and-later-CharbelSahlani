#!/bin/sh
# Script to create a file in a specified directory and write to it a specific string
# Author: Charbel Al Sahlani

# Exit if no argument provided
if [ -z "$1" ]; then
    echo "Error: Please provide a full file path."
    echo "Usage: $0 /path/to/directory/filename.ext 'your content'"
    exit 1
fi

# Exit if 2nd argument not provided
if [ -z "$2" ]; then
    echo "Error: No string provided." >&2
    exit 1
fi

# Getting arguments from input after passing the arguments' checks
writefile="$1"
writestr="$2"
# Extract the directory portion and the filename portion
TARGET_DIR=$(dirname "$writefile")
FILE_NAME=$(basename "$writefile")

# Attempt to create the extracted directory structure
# Use /dev/null to prevent the mkdir from printing an error in case of an error
# '2>&1' captures the exact system error message if it fails
if mkdir -p "$TARGET_DIR" 2> /dev/null; then
    echo "Directory structure verified/created successfully."
    
    # Write the content to the file inside the verified directory
    if echo "$writestr" > "$writefile"; then
        echo "Success: File successfully saved to $writefile"
    else
        echo "Error: Failed to write data to $writefile (Check storage or write permissions)."
        exit 1
    fi
else
    echo "Critical Error: Cannot create directory path '$TARGET_DIR'."
    echo "System reason: $(mkdir -p "$TARGET_DIR" 2>&1)"
    exit 1
fi