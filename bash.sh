#!/usr/bin/env bash

pmd_config_path="config/scanner/pmd_config.xml"
ignored_modules=(
  "destructiveChanges"
)
output_directory="output"
( mkdir -p $output_directory )

do_scan() {
  for module in src/*; do
    module_name=${module##*/}
    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
      module_directory="$output_directory"/"$module_name"
      ( mkdir -p "$module_directory" )

      set_report_output "all-engines" "xml"
            run_scanner "default" "junit"
            set_report_output "all-engines" "html"
            run_scanner "default" "html"

            set_report_output "pmd" "xml"
            run_scanner "pmd" "junit"
            set_report_output "pmd" "html"
            run_scanner "pmd" "html"
    fi
  done
}

set_report_output() {
  report_name=$1-"$module_name"-$(date +"%Y-%m-%d")-$(date +"%H-%M-%S").$2
  report_output_path="$module_directory"/"$report_name"
}

run_scanner() {
  scanner_config="--target $module --format $2 --outfile "$report_output_path""
  if [[ $1 == *"pmd"* ]]; then
    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
  fi
  sf scanner run $scanner_config
}

#set_report_output() {
#  report_name=$1-"$module_name"-$(date +"%Y-%m-%d")-$(date +"%H-%M-%S").$2
#  report_output_path="$module_directory"/"$report_name"
#}
#
#run_scanner() {
#  scanner_config="--target src/$module_name --format $2 --outfile "$report_output_path""
#  if [[ $1 == *"pmd"* ]]; then
#    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
#  fi
#  sf scanner run $scanner_config
#}
#
#module_name=$1
#if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
#  module_directory="$output_directory"/"$module_name"
#  ( mkdir -p "$module_directory" )
#  set_report_output "all-engines" "xml"
#  run_scanner "default" "junit"
#fi

git config --global --add safe.directory "*"
echo "output_directory=$output_directory" >> "$GITHUB_OUTPUT"

do_scan "$@"; exit