#!/bin/bash

# script gets as parameter an array of module names
# if there is no any module name provided then script deploys all sources under /src folder
source_paths_to_deploy=('src/')
if [ -n "$1" ]; then
  source_paths_to_deploy=()
  for module in "$@"; do
      source_paths_to_deploy+=("src/$module")
  done
fi
if [ "$SKIP_ORG_INTERACTION" = "true" ]; then
  echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
else
  command_result=$(sf project generate manifest --source-dir "${source_paths_to_deploy[@]}" --name sourcePackage)
  echo "Package generated: $command_result"
fi