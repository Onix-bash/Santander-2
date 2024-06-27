#!/bin/bash

# Get git diff output
source_to_check_changes="origin/develop"
git_diff=$(git diff --name-only $source_to_check_changes)


# Function to extract unique folder names after the "data" folder
create_json() {
    local path=$1
    local json="{}"
    while IFS= read -r line; do
        # Extract the module name and folder name
        module=$(echo "$line" | sed -n 's|^src/\([^/]*\)/data/.*|\1|p')
        folder=$(echo "$line" | sed -n 's|^src/[^/]*/data/\([^/]*\)/.*|\1|p')

        # If both module and folder are extracted successfully
        if [[ -n "$module" && -n "$folder" ]]; then
            # Update the JSON structure
            json=$(echo "$json" | jq --arg module "$module" --arg folder "$folder" '.[$module] += [$folder] | .[$module] = (.[$module] | unique)')
        fi
    done <<<"$path"
    echo "$json"
}

# Convert file paths to JSON
json_output=$(create_json "$git_diff")

# Output the JSON
echo "$json_output"

modules=( $(cd ../src/; ls -1p | grep / | sed 's|/$||') )

for module in "${modules[@]}"; do
    echo "$module"
    if jq -e --arg module "$module" 'has($module)' <<< "$json_output" >/dev/null; then
        echo "Folder $module found in JSON output"
       folders=$(jq -r --arg module "$module" '.[$module][]' <<< "$json_output")
               for folder in $folders; do
                  echo "Current directory: $(pwd)"
                   cd "../src/$module/data/$folder" || { echo "Directory ../src/$module/data/$folder not found"; exit 1; }
                   # Perform your desired operations here
                   # Example: set_input_version "$module/$folder"
               done

    else
        echo "Folder $module not found in JSON output"
    fi
done

