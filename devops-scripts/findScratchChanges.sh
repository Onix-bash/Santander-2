#!/bin/bash
git config --global --add safe.directory "*"
current_branch=$1
git fetch origin
git stash push -m "temporary stash" && git checkout origin/develop

#sf project retrieve start --metadata ExpressionSetDefinition --output-dir scratch_es --ignore-conflicts

DIR1="scratch_es/main/default/expressionSetDefinition"
DIR2="src"

## Check if the retrieval command was successful
if [ ! -d "$DIR1" ] || [ -z "$(ls -A "$DIR1")" ]; then
    echo "ExpressionSets wasn't retrieved from CI-Org."
fi

changed_files=$(diff -qr "$DIR1" "$DIR2" | grep -E '^Files ' | awk '{print $2}' | sed "s|^$DIR1/||")

if [ -n "$changed_files" ]; then
    echo "Differences found in:"
    echo "$changed_files"

    # Step 6: Generate the manifest
    sf project generate manifest --metadata ExpressionSetDefinition --name expressionSetManifest

    # Step 7: Clean the manifest to include only changed files
    for file in $changed_files; do
        # Ensure the manifest file exists before attempting to modify it
        if [ -f "expressionSetManifest.xml" ]; then
            xmlstarlet ed -L \
                -d "//members[. != '*'][not(. = '${file%%/*}')] | //members[. = '*']" \
                expressionSetManifest.xml
        fi
    done

    # Step 8: Deploy the changed files using the cleaned manifest
    if [ -f "expressionSetManifest.xml" ]; then
        cat expressionSetManifest.xml
#        sf project deploy start --manifest expressionSetManifest.xml --target-org CI-Org --test-level RunLocalTests --ignore-warnings --ignore-conflicts --verbose
    fi
else
    echo "No differences, nothing to deploy."
fi

echo "$current_branch"
git checkout -- .
git checkout "$current_branch"
git checkout -- .