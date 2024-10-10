#!/bin/bash

# Query the DeveloperName from Salesforce
current_es=$(sf data query --query "SELECT DeveloperName FROM ExpressionSetDefinition" --json)

# Use find to locate all .expressionSetDefinition-meta.xml files in the directory tree
existing_files=$(find "src" -type f -path "*/expressionSetDefinition/*" -name "*.expressionSetDefinition-meta.xml")

# Create a list of existing files without extensions and paths
existing_files_list=()
for file in $existing_files; do
  base_name=$(basename "$file" .expressionSetDefinition-meta.xml)
  existing_files_list+=("$base_name")
done

# Iterate over each DeveloperName
echo "$current_es" | jq -r '.result.records[].DeveloperName' | while read -r name; do
  file_exists=false
  for existing_file in "${existing_files_list[@]}"; do
    if [[ "$existing_file" == "$name" ]]; then
      file_exists=true
      break
    fi
  done

  if [ "$file_exists" = false ]; then
    echo "!**/expressionSetDefinition/${name}.expressionSetDefinition-meta.xml" >> .forceignore
    echo "${name}"
  fi
done
