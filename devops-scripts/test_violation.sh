#!/bin/bash

# script gets as parameter an array of module names
# if there is no any module name provided then script validates all sources under /src folder

source_paths_to_scan=('src/')
if [ -n "$1" ]; then
  source_paths_to_scan=()
  for module in "$@"; do
      source_paths_to_scan+=("src/$module")
  done
fi

echo "${source_paths_to_scan[@]}"
# Run scanner using All engines with custom PMD config
mkdir -p "output"
sf scanner:run --target "${source_paths_to_scan[@]}" --severity-threshold=2 --verbose-violations --format json --pmdconfig "config/scanner/pmd_config.xml" --outfile output/report.json

# Read the JSON output and format it
JSON_OUTPUT=$(cat output/report.json)
FORMATTED_JSON=$(echo "$JSON_OUTPUT" | jq '.')

# Write the formatted JSON to the GITHUB_OUTPUT environment file
echo "report<<EOF" >> "$GITHUB_OUTPUT"
echo "$FORMATTED_JSON" >> "$GITHUB_OUTPUT"
echo "EOF" >> "$GITHUB_OUTPUT"