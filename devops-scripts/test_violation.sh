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

# Remove newline characters from message field and filter by severity <= 2
FILTERED_JSON=$(echo "$JSON_OUTPUT" | jq '[.[] | {engine, fileName, violations: [.violations[] | select(.severity <= 2) | .message |= gsub("\\n"; "") ]} | select(.violations | length > 0)]')

# Output the scan report to the console
echo "$FILTERED_JSON"

# Exit with an error if there are any violations with severity <= 2
SEVERITY_COUNT=$(echo "$FILTERED_JSON" | jq 'map(.violations) | flatten | length')
if [ "$SEVERITY_COUNT" -gt 0 ]; then
  echo "There are $SEVERITY_COUNT violations with severity 2 or lower."
  exit 1
else
  echo "No violations with severity 2 or lower found."
fi