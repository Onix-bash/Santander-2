#!/bin/bash

echo "--- Starting validation for modules: ${source_paths_to_validate[*]}"
echo "$SKIP_ORG_INTERACTION"

# Track "Deployment Id" allowing to Cancel the Job
#validate_command_result=$(sf project deploy validate --manifest sourcePackage.xml --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" --test-level RunSpecifiedTests --tests "${testClasses[@]}" --ignore-warnings --async --json)
#
#echo "Validation job details: $validate_command_result"
#deployment_id=$(echo "$validate_command_result" | jq -r .result.id)
#echo "deployment_id=$deployment_id" >> "$GITHUB_OUTPUT"
#sf project deploy resume --job-id $deployment_id
