#!/bin/bash
git config --global --add safe.directory "*"
current_branch=$1
git fetch origin
git stash push -m "temporary stash" && git checkout origin/develop

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
all_expression_sets_dir="all_expression_sets"

# Create the directory to store combined files
mkdir -p "$all_expression_sets_dir"

# Find all expressionSetDefinition directories and copy files to the combined directory
src_dirs=$(find src -type d -name 'expressionSetDefinition')

for dir in $src_dirs; do
    echo "Processing directory: $dir"
    # Copy files to the combined directory without preserving the parent directory structure
    find "$dir" -type f -exec cp {} "$all_expression_sets_dir/" \;
done

# Compare DIR1 with the combined directory
changed_files=$(diff -qr "$DIR1" "$all_expression_sets_dir" | grep -E '^Files ' | awk '{print $2, $4}' | sed "s|^$DIR1/||")

# Extract base names without paths or file extensions and remove duplicates
unique_names=$(echo "$changed_files" | sed -e 's|.*/||' -e 's/\.expressionSetDefinition-meta\.xml$//' | sort -u)

# Check if there are any changed files
if [ -n "$unique_names" ]; then
    echo "Differences found in:"
    echo "$unique_names"

    # Generate the manifest
    sf project generate manifest --metadata ExpressionSetDefinition --name expressionSetManifest

    # Clean the manifest to include only changed files
    manifest_file="expressionSetManifest.xml"
    temp_manifest="temp_manifest.xml"

    # Copy the original manifest to a temporary file for editing
    cp "$manifest_file" "$temp_manifest"

    # Remove the wildcard <members>*</members> from the manifest
    sed -i '/<members>\*<\/members>/d' "$temp_manifest"

    # Add changed files to the manifest
    for name in $unique_names; do
        # Add the new member entry before the closing </types> tag
        sed -i "/<\/types>/i <members>$name</members>" "$temp_manifest"
    done

    # Move the updated manifest to the original file
    mv "$temp_manifest" "$manifest_file"

    # Deploy the changed files using the cleaned manifest
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