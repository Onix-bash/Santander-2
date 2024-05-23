#!/usr/bin/env bash

set_input_version() {
  echo "Current directory: $(pwd)"
  # Prepare JSON for the new Matrix Version
  current_matrix_id=$(jq -r '.records[].CalculationMatrix.Id' CalculationMatrixVersion.json)
echo "Current matrix id: '$current_matrix_id'"
#  # Create the correct Key and Value
#  set_matrix_id=$(
#    jq '.records[] |= . + {"CalculationMatrixId": "'$current_matrix_id'"}' CalculationMatrixVersion.json
#  )
#  echo "$set_matrix_id" > CalculationMatrixVersion.json
#
#  # Delete unnecessary property
#  delete_matrix_property=$(
#    jq 'del(.records[].CalculationMatrix)' CalculationMatrixVersion.json
#  )
#  echo "$delete_matrix_property" > CalculationMatrixVersion.json
#
#  # Create Inactive Matrix Version from JSON
#  create_matrix_data
}

# Create Matrix Version and Matrix Rows
create_matrix_data() {
  # Create Inactive Matrix Version from JSON
  create_new_matrix_version=$(sf data import tree --files CalculationMatrixVersion.json --json)
  echo "$create_new_matrix_version"
  # Check if Inactive Matrix Version was created successfully
  if [ $? -eq 0 ]; then
    # Get Inactive Matrix Version Id
    new_matrix_version_id=$(echo "$create_new_matrix_version" | jq -r .result[].id)

    # Set Inactive Matrix Version Id into JSON that has Matrix Rows
    set_matrix_version_id=$(jq '.records[] |= . + {
          "CalculationMatrixVersionId": "'$new_matrix_version_id'"
    }' CalculationMatrixRow.json)
    echo "$set_matrix_version_id" > CalculationMatrixRow.json

    # Create Matrix Rows
    create_matrix_rows

  else
    # Show an Error
    echo "$create_new_matrix_version" | jq -c -r '.message'
  fi
}

# Creates Matrix Rows
create_matrix_rows() {
  data_import=$(sf data import tree --files CalculationMatrixRow.json)
  echo "$data_import"
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
  sf_updated=$(sf data update record --sobject CalculationMatrixVersion --record-id "$new_matrix_version_id" --values "IsEnabled=true")
  echo "$sf_updated"
  # Check if Enabling Matrix Version was successfully
  if [ $? -eq 0 ]; then
    echo "Matrix Version was Enabled successfully"
    # Get Id of the previously enabled Matrix Version. It should be disabled after enabling the first one
    current_matrix_version_id=$(sf data query --query "SELECT Id FROM CalculationMatrixVersion WHERE IsEnabled = TRUE AND CalculationMatrixId = '$current_matrix_id' AND Id != '$new_matrix_version_id' LIMIT 1" --json | jq -r .result.records[].Id)
    echo "$current_matrix_version_id"
    # Disable the previous Matrix Version
    disable_matrix_version

  else
    # Error. Delete Matrix Version to allow the next attempt
    delete_matrix_version
  fi
}

# Disables the previous Matrix Version
disable_matrix_version() {
  sf_data=$(sf data update record --sobject CalculationMatrixVersion --record-id "$current_matrix_version_id" --values "IsEnabled=false")
  echo "$sf_data"
  # Check if Disabling Matrix Version was successfully
  if [ $? -eq 1 ]; then
    # Error. Delete Matrix Version to allow the next attempt
    delete_matrix_version
  fi
}

# Deletes Matrix Version if any of the steps in transaction was failed
delete_matrix_version() {
  sf data delete record --sobject CalculationMatrixVersion --record-id "$new_matrix_version_id"
}

checkFolders() {
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

  json_output=$(create_json "$git_diff")
  echo "$json_output"

  modules=( $(cd ../src/; ls -1p | grep / | sed 's|/$||') )
  original_dir=$(pwd)
  for module in "${modules[@]}"; do
      echo "$module"
      if jq -e --arg module "$module" 'has($module)' <<< "$json_output" >/dev/null; then
         folders=$(jq -r --arg module "$module" '.[$module][]' <<< "$json_output")
         cd "$original_dir" || exit 1
                 for folder in $folders; do
                   # Go to folder with CalculationMatrixVersion.json
                   cd "../src/$module/data/$folder" || exit 1
                   set_input_version
                 done
      else
          echo "Folder $module not found in JSON output"
      fi
  done
}

# Start
checkFolders "$@"; exit