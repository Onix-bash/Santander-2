#!/bin/bash

# DMD - decisionMatrixDefinition
# DMV - decisionMatrixVersion/calculationMatrixVersion

# Get the passed files with changed DMD
changed_decision_matrix_files=("$@")

# Check if there are any files passed, so no CalculationMatrixRow(s) to create
if [[ ${#changed_decision_matrix_files[@]} -eq 0 ]]; then
  # Exit if changed files not provided
  exit 0
fi

echo "Create CalculationMatrixVersionRows for:"
echo "${changed_decision_matrix_files[@]}"

# Initialize JSON array with DMD data
changed_dmv="["

for file_path in "${changed_decision_matrix_files[@]}"; do
  # Extract the decisionMatrixDefinition name and its last version
  dmd_name=$(sed -n '/<decisionMatrixDefinition>/{s/.*<decisionMatrixDefinition>\(.*\)<\/decisionMatrixDefinition>.*/\1/;p;q;}' "$file_path")
  last_version_number=$(sed -n 's|.*<versionNumber>\(.*\)</versionNumber>|\1|p' "$file_path" | sort -nr | head -n 1 | tr -d ' ')

  # Construct the JSON object
  json_object="{\"decisionMatrixDefinition\": \"$dmd_name\", \"versionNumber\": \"$last_version_number\"}"
  changed_dmv+="$json_object, "
done
# Finalize the JSON array
changed_dmv="${changed_dmv%, }]"
echo "$changed_dmv" > decision_matrix_versions.json

# Get CalculationMatrixVersion Id for each changed DMV
echo "$changed_dmv" | jq -c '.[]' | while read -r item; do
  DMD=$(echo "$item" | jq -r '.decisionMatrixDefinition')
  versionNumber=$(echo "$item" | jq -r '.versionNumber')

  current_dmv_id=$(sf data query --query "SELECT Id FROM CalculationMatrixVersion
    WHERE CalculationMatrixId IN (SELECT Id FROM CalculationMatrix WHERE UniqueName='$DMD')
    AND VersionNumber=$versionNumber LIMIT 1" --json | jq -r '.result.records[0].Id')

  # Read CalculationMatrixRow.json for each DMD 
  output_file_path="data/calculationMatrixRow/$DMD/CalculationMatrixRow.json"

  # Set CalculationMatrixRow.json with the DMV ID
  if [[ -n "$output_file_path" && -n $current_dmv_id ]]; then
    jq --arg id "$current_dmv_id" '.records[] |= . + { "CalculationMatrixVersionId": $id }' "$output_file_path" > tmp.json && mv tmp.json "$output_file_path"

    # Create CalculationMatrixRow(s)
    if sf data import tree --files "$output_file_path" --json; then
      echo "All CalculationMatrixRow(s) were created successfully."
    else
      echo "Error creating CalculationMatrixRow(s) for $DMD with version $versionNumber"
      exit 1
    fi
  else
    echo "No CalculationMatrixRow(s) were found for $DMD with version $versionNumber"
  fi
done