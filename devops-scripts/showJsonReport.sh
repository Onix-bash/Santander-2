#!/bin/sh
# Read the JSON output and format it
JSON_OUTPUT=$(cat output/report.json)
FORMATTED_JSON=$(echo "$JSON_OUTPUT" | jq 'walk(if type == "object" and .message? then .message |= gsub("\\n"; "") else . end)')

# Output the scan report to the console
echo "$FORMATTED_JSON"