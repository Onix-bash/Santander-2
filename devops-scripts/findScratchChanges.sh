#!/bin/bash
git config --global --add safe.directory "*"
current_branch=$1
git fetch origin
git stash push -m "temporary stash" && git checkout origin/develop

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
src_dirs=$(find src -type d -name 'expressionSetDefinition')

# Initialize an empty list of changed files
changed_files=""

# Loop through each directory found in src/
for dir in $src_dirs; do
    echo "Processing directory: $dir"

    # Determine the corresponding directory in DIR1
    relative_path=$(echo "$dir" | sed 's|^src/||')
    dir_in_scratch_es="$DIR1/$(basename "$relative_path")"

    # Check if the corresponding directory exists in scratch_es
    if [ -d "$dir_in_scratch_es" ]; then
        # Loop through files in the src directory
        find "$dir" -type f | while read -r file_in_src; do
            relative_file_path="${file_in_src#$dir/}"  # Get the relative file path
            file_in_scratch_es="$dir_in_scratch_es/$relative_file_path"

            # Check if the file exists in DIR1 and if it's different from the file in DIR2
            if [ ! -f "$file_in_scratch_es" ] || ! diff -q "$file_in_scratch_es" "$file_in_src" > /dev/null; then
                # File is new or changed
                echo "$relative_file_path"
                changed_files+="$relative_file_path "
            fi
        done
    else
        echo "No matching directory in scratch_es for $dir."
    fi
done

if [ -n "$changed_files" ]; then
     echo "Differences found in:"
     echo "$changed_files"

     # Step 6: Generate the manifest
     sf project generate manifest --metadata ExpressionSetDefinition --name expressionSetManifest

     # Step 7: Clean the manifest to include only changed files
     manifest_file="expressionSetManifest.xml"
     temp_manifest="temp_manifest.xml"

     # Copy the original manifest to a temporary file for editing
     cp "$manifest_file" "$temp_manifest"

     # Remove the wildcard <members>*</members> from the manifest
     sed -i '/<members>\*<\/members>/d' "$temp_manifest"

     # Add changed files to the manifest
     for file in $changed_files; do
         # Ensure the file path format is correct
         file_path=$(echo "$file" | sed 's|^src/||')
         # Add the new member entry before the closing </types> tag
         sed -i "/<\/types>/i <members>$file_path</members>" "$temp_manifest"
     done

     # Move the updated manifest to the original file
     mv "$temp_manifest" "$manifest_file"

     # Step 8: Deploy the changed files using the cleaned manifest
     if [ -f "$manifest_file" ]; then
          cat $manifest_file
#         sf project deploy start --manifest "$manifest_file" --target-org CI-Org --test-level RunLocalTests --ignore-warnings --ignore-conflicts --verbose
     fi
 else
     echo "No differences, nothing to deploy."
 fi

echo "$current_branch"
git checkout -- .
git checkout "$current_branch"
git checkout -- .