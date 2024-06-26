#!/usr/bin/env bash

git config --global --add safe.directory "*"
source_to_check_changes="origin/develop"
acceptable_folders=(
  "LookupTable"
)
if [ -n "$1" ]; then
  source_to_check_changes=$1
fi

start() {
  echo "feature/deploy-test-pr"
  # Array of your module directories
  modules=( $(cd src/; ls -1p | grep / | sed 's|/$||') )

git fetch origin
  # Initialize an associative array to hold the diffs by module

  get_filepath_from_acceptable_folders() {
    module=$1

    for folder in "${acceptable_folders[@]}"; do
      if [[ $file == src/$module/data/$folder/* && $is_set_input_version_run == false ]]; then
        cd "$original_dir" && cd "src/$module/data/$folder" || exit 1
        echo "Start set_input_version for module/folder: '$module/$folder'"
        set_input_version
        is_set_input_version_run=true
      fi
    done
  }

  original_dir=$(pwd)
  for module in "${modules[@]}"; do
    # Flag to track if set_input_version has been called for this module
    is_set_input_version_run=false

    # Get the list of changed files use pattern "src/$module/data"
    git_diff=$(git diff-index --name-only $source_to_check_changes | grep "^src/$module/data")
    echo "git_diff in src/module-name/data files: '$git_diff'"

    # Iterate over each changed file
    for file in $git_diff; do
      # Check if the file is in one of the acceptable folders and call the function
      get_filepath_from_acceptable_folders "$module"
    done
  done
}

set_input_version() {
  # Prepare JSON for the new Matrix Version
  current_matrix_id=$(jq -r '.records[].CalculationMatrix.Id' CalculationMatrixVersion.json)
  echo "current_matrix_id:'$current_matrix_id'"
  # Create the correct Key and Value
#  set_matrix_id=$(
#    jq '.records[] |= . + {"CalculationMatrixId": "'$current_matrix_id'"}' CalculationMatrixVersion.json
#  )
#  echo $set_matrix_id > CalculationMatrixVersion.json
#
#  # Delete unnecessary property
#  delete_matrix_property=$(
#    jq 'del(.records[].CalculationMatrix)' CalculationMatrixVersion.json
#  )
#  echo $delete_matrix_property > CalculationMatrixVersion.json
#
#  # Create Inactive Matrix Version from JSON
#  create_matrix_data
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

