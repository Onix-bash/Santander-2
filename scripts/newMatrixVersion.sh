#!/usr/bin/env bash

set_input_version() {
  # Prepare JSON for the new Matrix Version
  current_matrix_id=$(jq -r '.records[].CalculationMatrix.Id' CalculationMatrixVersion.json)

  # Create the correct Key and Value
  set_matrix_id=$(
    jq '.records[] |= . + {"CalculationMatrixId": "'$current_matrix_id'"}' CalculationMatrixVersion.json
  )
  echo "$set_matrix_id" > CalculationMatrixVersion.json

  # Delete unnecessary property
  delete_matrix_property=$(
    jq 'del(.records[].CalculationMatrix)' CalculationMatrixVersion.json
  )
  echo "$delete_matrix_property" > CalculationMatrixVersion.json

  # Create Inactive Matrix Version from JSON
  create_matrix_data
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

# Start
set_input_version "$@"; exit