#!/bin/bash
#git config --global --add safe.directory "*"
#current_branch=$1
#git fetch origin
#git stash push -m "temporary stash" && git checkout origin/develop

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

scratch_expression_sets_dir="scratch_es/expressionSetScratchDefinition"
branch_expression_sets_dir="all_expression_sets"

# Create the directory to store expression sets from all modules
mkdir -p "$branch_expression_sets_dir"

# Find all expressionSetDefinition directories and copy files to the combined directory
src_dirs=$(find src -type d -name 'expressionSetDefinition')
for dir in $src_dirs; do
    find "$dir" -type f -exec cp {} "$branch_expression_sets_dir/" \;
done

changed_files=""

# Compare files from the branch directory against the scratch directory
for branch_file in "$branch_expression_sets_dir"/*.expressionSetDefinition-meta.xml; do
    file_name=$(basename "$branch_file")
    scratch_file="$scratch_expression_sets_dir/$file_name"

    if [ -f "$branch_file" ] && [ -f "$scratch_file" ]; then
        # Extract versionNumber from both files
        branch_version=$(sed -n 's|.*<versionNumber>\(.*\)</versionNumber>|\1|p' "$branch_file")
        scratch_version=$(sed -n 's|.*<versionNumber>\(.*\)</versionNumber>|\1|p' "$scratch_file")


        if [ "$branch_version" != "$scratch_version" ]; then

            changed_files+="$file_name "
        fi
    elif [ -f "$branch_file" ] && [ ! -f "$scratch_file" ]; then
              # File exists in branch but not in scratch, consider it changed
              echo "branch_file % scratch_file  $file_name"
        changed_files+="$file_name "
    fi
done

expression_set_names=$(echo "$changed_files" | sed 's/\.expressionSetDefinition-meta\.xml//g')

echo "NAMES: $expression_set_names"

# Check if there are any changed files
if [ -n "$expression_set_names" ]; then

    sf project generate manifest --metadata ExpressionSetDefinition --name expressionSetManifest
    manifest_file="expressionSetManifest.xml"

    # Create copy of the original manifest to a temporary file for editing
    temp_manifest="temp_manifest.xml"
    cp "$manifest_file" "$temp_manifest"

    # Remove the <members> and add only changed
    sed -i '' '/<members>\*<\/members>/d' "$temp_manifest"

  for name in $expression_set_names; do
      # Add <members>$name</members> before the <name> tag in the temp_manifest file
      sed -i '' "/<name>/i\\
  <members>$name</members>" "$temp_manifest"
  done

    # Move the updated manifest to the original file
    mv "$temp_manifest" "$manifest_file"

    # Deploy the changed files to CI-Org
    if [ -f "$manifest_file" ]; then
        cat "$manifest_file"
#        sf project deploy start --manifest "$manifest_file" --target-org CI-Org --ignore-warnings --ignore-conflicts --verbose
    fi
else
    echo "No Expression Set changes, nothing to deploy."
fi

#echo "$current_branch"
#git checkout -- .
#git checkout "$current_branch"
#git checkout -- .