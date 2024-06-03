#!/bin/bash

# Set the directory path where the files are located
directory="../samples/grafana-dashboards"

# Set the placeholder string
# <Placeholder_SubID>
placeholder="af342bf1-1ace-41df-902c-47921400551b"

# Prompt the user to enter the new string
read -p "Enter the new string: " newString

# Iterate over each file in the directory
for file in "$directory"/*; do
    # Check if the file is not a directory
    if [ -f "$file" ]; then
        # Search for the placeholder string in the file
        if grep -q "$placeholder" "$file"; then
            # Replace the placeholder string with the new string
            sed -i "s/$placeholder/$newString/g" "$file"
            echo "Placeholder replaced in: $file"
        else
            echo "Placeholder not found in: $file"
        fi
    fi
done
