#!/bin/bash
# script gets as parameter an array of module names
# if there is no any module name provided then script validates all flows under /src folder

source_paths_to_scan=('src/')
if [ -n "$1" ]; then
  source_paths_to_scan=()
  for module in "$@"; do
      source_paths_to_scan+=("src/$module")
  done
fi
for module_path in ${source_paths_to_scan[*]}; do
  echo "--- Starting scanner for modules: $module_path"
  sf flow scan --config config/scanner/flow-scanner.json --failon error --directory "$module_path"
done
