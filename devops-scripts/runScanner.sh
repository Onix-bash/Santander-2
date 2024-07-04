#!/bin/bash

# script gets as parameter an array of module names
# if there is no any module name provided then script validates all modules in /src except IGNORED_MODULES

source_paths_to_scan=()

start() {
  if [ -n "$1" ]; then
    filter_modules_to_scan "$@"
  else
    modules=( $(cd src/; ls -1p | grep / | sed 's|/$||') )
    filter_modules_to_scan "${modules[@]}"
  fi

  echo "--- Starting scanner for modules: ${source_paths_to_scan[*]}"
  # Run scanner using All engines with custom PMD config
  if [ ${#source_paths_to_scan[@]} -eq 0 ]; then
    echo "No available modules to scan"
  else
    mkdir -p "output"

    sf scanner:run --target "${source_paths_to_scan[@]}" --severity-threshold=$SEVERITY --verbose-violations --format json --pmdconfig "config/scanner/pmd_config.xml" --outfile output/report.json

    # Read the JSON output and format it
    JSON_OUTPUT=$(cat output/report.json)

    # Remove newline characters from message field and filter by severity
    FILTERED_JSON=$(echo "$JSON_OUTPUT" | jq --arg severity "$SEVERITY" '[.[] | {engine, fileName, violations: [.violations[] | select(.severity <= ($severity | tonumber)) | .message |= gsub("\\n"; "") ]} | select(.violations | length > 0)]')

    # Output the scan report to the console
    echo "$FILTERED_JSON"

    # Exit with an error if there are any violations
    SEVERITY_COUNT=$(echo "$FILTERED_JSON" | jq 'map(.violations) | flatten | length')
    if [ "$SEVERITY_COUNT" -gt 0 ]; then
      echo "There are $SEVERITY_COUNT violations with severity $SEVERITY or lower."
      exit 1
    fi
  fi
}

filter_modules_to_scan() {
  local modules_to_scan=("$@")
  echo "${modules_to_scan[@]}"
  for module in "${modules_to_scan[@]}"; do
    if ! [[ ${IGNORED_MODULES[*]} =~ (^|[[:space:]])"$module"($|[[:space:]]) ]]; then
      source_paths_to_scan+=("src/$module")
    fi
  done
}

start "$@"; exit