#!/bin/bash

# Define the path to the src-temp folder
temp_folder="./src-temp"


    # Count the number of files and folders in the src-temp folder
    num_items=$(ls -A "$temp_folder" | wc -l)

    # Check if there are any items other than README.md
    if [ "$num_items" -gt 1 ]; then
        echo "other files/folders found in src-temp. Kindly remove files/folders other than README.md file"
        exit 1
    else
        echo "no extra files/folders found in src-temp"
    fi