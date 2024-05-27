#!/usr/bin/env bash

acceptable_folders=(
  "LookupTable"
)

# Array of your module directories
modules=( $(cd src/; ls -1p | grep / | sed 's|/$||') )

git config --global --add safe.directory "*"
source_to_check_changes="origin/feature/deploy-test"

start() {
  echo "deploy-test-pr"
  git fetch origin
  git_diff=$(git diff-index --name-only $source_to_check_changes)
  echo "git_diff: '$git_diff'"

declare -A module_diffs

# Iterate over each module
for module in "${modules[@]}"; do
  # Get the list of changed files
  diff=$(git diff-index --name-only $source_to_check_changes)

  # Iterate over each changed file
  for file in $diff; do
    # Check if the file matches the pattern "src/$module/data"
    if [[ $file == src/$module/data* ]]; then
      # Append the file to the module's list of diffs
      module_diffs["$module"]+="$file "
    fi
  done
done

# Convert the associative array to JSON format
json="{"
for module in "${!module_diffs[@]}"; do
  files=(${module_diffs[$module]})
  json+="\"$module\":["
  for file in "${files[@]}"; do
    json+="\"$file\","
  done
  json=${json%,}  # Remove the trailing comma
  json+="],"
done
json=${json%,}  # Remove the trailing comma
json+="}"

# Print the JSON object
echo "new_json: '$json'"
  # Function to extract unique folder names in "src/module_name/data" folder
  create_json() {
    local path=$1

    local json="{}"
    while IFS= read -r line; do
      # Extract the module name and folder name
      module=$(echo "$line" | sed -n 's|^src/\([^/]*\)/data/.*|\1|p')
      folder=$(echo "$line" | sed -n 's|^src/[^/]*/data/\([^/]*\)/.*|\1|p')
      echo "$module"
      echo "$folder"
      # If both module and folder are extracted successfully
      if [[ -n "$module" && -n "$folder" ]]; then

        json=$(echo "$json" | jq --arg module "$module" --arg folder "$folder" '.[$module] += [$folder] | .[$module] = (.[$module] | unique)')
      fi
    done <<<"$path"
    echo "$json"
  }

  find_acceptable_folder_files() {
    local module="$1"
    local folders="$2"
    echo "Finding acceptable folder files in module $module for folders: $folders"
    for folder in $folders; do
         # Check if the folder is acceptable
         if [[ ${acceptable_folders[*]} =~ (^|[[:space:]])"$folder"($|[[:space:]]) ]]; then
           # Go to folder with CalculationMatrixVersion.json
           cd "src/$module/data/$folder" || exit 1
           echo "Start function for folder: '$folder' "return
#           set_input_version
         fi
    done
  }

  json_output=$(create_json "$git_diff")
  echo "Json with modules changes: '$json_output'"

  original_dir=$(pwd)

  # Loop through each module to find matrix_data
  for module in "${modules[@]}"; do
      echo "$module'"
      if jq -e --arg module "$module" 'has($module)' <<< "$json_output" >/dev/null; then
         folders=$(jq -r --arg module "$module" '.[$module][]' <<< "$json_output")
         echo "$folders'"
         cd "$original_dir" || exit 1
         find_acceptable_folder_files "$module" "$folders"
       fi
   done
}

set_input_version() {
  # Prepare JSON for the new Matrix Version
  current_matrix_id=$(jq -r '.records[].CalculationMatrix.Id' CalculationMatrixVersion.json)

  # Create the correct Key and Value
  set_matrix_id=$(
    jq '.records[] |= . + {"CalculationMatrixId": "'$current_matrix_id'"}' CalculationMatrixVersion.json
  )
  echo $set_matrix_id > CalculationMatrixVersion.json

  # Delete unnecessary property
  delete_matrix_property=$(
    jq 'del(.records[].CalculationMatrix)' CalculationMatrixVersion.json
  )
  echo $delete_matrix_property > CalculationMatrixVersion.json

  # Create Inactive Matrix Version from JSON
  create_matrix_data
}

# Create Matrix Version and Matrix Rows
create_matrix_data() {
  # Create Inactive Matrix Version from JSON
  create_new_matrix_version=$(sf data import tree --files CalculationMatrixVersion.json --json)

  # Check if Inactive Matrix Version was created successfully
  if [ $? -eq 0 ]; then
    # Get Inactive Matrix Version Id
    new_matrix_version_id=$(echo "$create_new_matrix_version" | jq -r .result[].id)

    # Set Inactive Matrix Version Id into JSON that has Matrix Rows
    set_matrix_version_id=$(jq '.records[] |= . + {
          "CalculationMatrixVersionId": "'$new_matrix_version_id'"
    }' CalculationMatrixRow.json)
    echo $set_matrix_version_id > CalculationMatrixRow.json

    # Create Matrix Rows
    create_matrix_rows

  else
    # Show an Error
    echo $create_new_matrix_version | jq -c -r '.message'
  fi
}

# Creates Matrix Rows
create_matrix_rows() {
  sf data import tree --files CalculationMatrixRow.json
  # Check if Matrix Rows were created successfully
  if [ $? -eq 0 ]; then
    echo "All Matrix Rows were created successfully"
    enable_matrix_version
  else
    # Error. Delete Matrix Version to allow the next attempt
    delete_matrix_version
  fi
}

# Enables the latest Matrix Version
enable_matrix_version() {
  sf data update record --sobject CalculationMatrixVersion --record-id $new_matrix_version_id --values "IsEnabled=true"

  # Check if Enabling Matrix Version was successfully
  if [ $? -eq 0 ]; then
    echo "Matrix Version was Enabled successfully"
    # Get Id of the previously enabled Matrix Version. It should be disabled after enabling the first one
    current_matrix_version_id=$(sf data query --query "SELECT Id FROM CalculationMatrixVersion WHERE IsEnabled = TRUE AND CalculationMatrixId = '$current_matrix_id' AND Id != '$new_matrix_version_id' LIMIT 1" --json | jq -r .result.records[].Id)
    # Disable the previous Matrix Version
    disable_matrix_version

  else
    # Error. Delete Matrix Version to allow the next attempt
    delete_matrix_version
  fi
}

# Disables the previous Matrix Version
disable_matrix_version() {
  sf data update record --sobject CalculationMatrixVersion --record-id $current_matrix_version_id --values "IsEnabled=false"
  # Check if Disabling Matrix Version was successfully
  if [ $? -eq 1 ]; then
    # Error. Delete Matrix Version to allow the next attempt
    delete_matrix_version
  fi
}

# Deletes Matrix Version if any of the steps in transaction was failed
delete_matrix_version() {
  sf data delete record --sobject CalculationMatrixVersion --record-id $new_matrix_version_id
}


# Start

start "$@"; exit

