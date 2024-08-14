#!/bin/bash
git config --global --add safe.directory "*"
current_branch=$1
git fetch origin
git stash push -m "temporary stash" && git checkout origin/develop

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

scratch_expression_sets_dir="scratch_es/main/default/expressionSetDefinition"
branch_expression_sets_dir="all_expression_sets"

# Create the directory to store expression_sets from all modules
mkdir -p "$branch_expression_sets_dir"

# Find all expressionSetDefinition directories and copy files to the combined directory
src_dirs=$(find src -type d -name 'expressionSetDefinition')
for dir in $src_dirs; do
    find "$dir" -type f -exec cp {} "$branch_expression_sets_dir/" \;
done

changed_files=$(diff -qr "$scratch_expression_sets_dir" "$branch_expression_sets_dir" | grep -E '^Files ' | awk '{print $2, $4}' | sed "s|^$scratch_expression_sets_dir/||")
# Extract base names without paths or file extensions and remove duplicates
expression_set_names=$(echo "$changed_files" | sed -e 's|.*/||' -e 's/\.expressionSetDefinition-meta\.xml$//' | sort -u)

# Check if there are any changed files
if [ -n "$expression_set_names" ]; then

    sf project generate manifest --metadata ExpressionSetDefinition --name expressionSetManifest
    manifest_file="expressionSetManifest.xml"

    # Create copy of the original manifest to a temporary file for editing
    temp_manifest="temp_manifest.xml"
    cp "$manifest_file" "$temp_manifest"

    # Remove the <members> and add only changed
    sed -i '/<members>\*<\/members>/d' "$temp_manifest"
    for name in $expression_set_names; do
      # Add file before <name> tag
      sed -i "/<name>/i <members>$name</members>" "$temp_manifest"
    done

    # Move the updated manifest to the original file
    mv "$temp_manifest" "$manifest_file"

    # Deploy the changed files to CI-Org
    if [ -f "$manifest_file" ]; then
        cat "$manifest_file"
        # Uncomment the following line to perform deployment
        # sf project deploy start --manifest "$manifest_file" --target-org CI-Org --test-level RunLocalTests --ignore-warnings --ignore-conflicts --verbose
    fi
else
    echo "No differences, nothing to deploy."
fi

echo "$current_branch"
git checkout -- .
git checkout "$current_branch"
git checkout -- .