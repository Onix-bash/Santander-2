#!/usr/bin/env bash

pmd_config_path="config/scanner/pmd_config.xml"
ignored_modules=(
  "destructiveChanges"
)

# Create temporary files
output_directory="output"
mkdir -p "$output_directory"

report_file="$output_directory/report.html"
details_file="$output_directory/details_file.html"
summary_table="$output_directory/summary_table.html"

start() {
  # Run Scanner
  for module in src/*; do
    module_name=${module##*/}
    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
      # Create Module directory
      module_directory="$output_directory"/"$module_name"
      mkdir -p "$module_directory"

      # Run Scanner in CSV for Summary Tab and in HTML type for Storing as Artifacts
      set_report_output "all-engines" "html"
      run_scanner "default" "html"
      set_report_output "pmd" "html"
      run_scanner "pmd" "html"

      set_report_output "all-engines" "csv"
      run_scanner "default" "csv"
      default_csv_file="$report_output_path"

      set_report_output "pmd" "csv"
      run_scanner "pmd" "csv"
      pmd_csv_file="$report_output_path"

      show_scanner_results "$module_name" "$default_csv_file" "default"
      show_scanner_results "$module_name" "$pmd_csv_file" "custom"
    fi
  done

  unit_tables
}

# Set Output Name & Path for each Module
set_report_output() {
  report_name="$1-$module_name-$(date +"%Y-%m-%d-%H-%M-%S").$2"
  report_output_path="$module_directory/$report_name"
}

# Run Scanner using different Engines
run_scanner() {
  local scanner_config="--target $module --format $2 --outfile $report_output_path"
  if [[ $1 == "pmd" ]]; then
    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
  fi
  sf scanner run $scanner_config
}

# Show Scanner Results on the Job Summary page (from CSV into GIT Markdown)
show_scanner_results() {
  local module_name=$1
  local csv_file=$2
  local scan_mode=$3

  local module_full_name="${module_name}_${scan_mode}"

  # Read CSV data from file
  csv_data=$(< "$csv_file")

  # Calculate the number of failed entries (rows)
  fail_count=$(echo "$csv_data" | awk -F',' 'NR > 1 {count++} END {print count}')

  # Write the module's detailed report
  {
    cat <<EOL
<details id="$module_full_name" class="mx-3"><summary>$module_full_name</summary>
<p></p>
<table>
<tr>
  <th>Threshold</th>
  <th>Component Name</th>
  <th>Description</th>
</tr>
EOL

    # Parse CSV into GIT Markdown
    echo "$csv_data" | awk -F',' 'NR > 1 {
      # Remove leading and trailing quotes
      for (i = 1; i <= NF; i++) {
          gsub(/^"|"$/, "", $i)
      }

      # Extract values
      threshold = $2
      file = $3
      line = $4
      column = $5
      rule = $6
      description = $7
      url = $8
      category = $9

      # Extract component name from file path
      split(file, path_parts, "/")
      component = path_parts[length(path_parts)]

      # Print Table Row
      printf "    <tr>\n"
      printf "        <td>%s</td>\n", threshold
      printf "        <td>%s</td>\n", component
      printf "        <td>%s\n", description
      printf "            <br/>Category: %s - %s\n", category, rule
      printf "            <br/>File: %s\n", file
      printf "            <br/>Line: %s\n", line
      printf "            <br/>Column: %s\n", column
      printf "            <br/><a href=\"%s\" target=\"_blank\" title=\"%s\">%s</a></td>\n", url, rule, rule
      printf "    </tr>\n"
    }'

    cat <<EOL
    </table>
    </details>
EOL
  } >> "$details_file"

  {
    cat <<EOL
  <tr>
    <td><a href="#user-content-$module_full_name" title="$module_full_name">$module_full_name</a></td>
    <td>$fail_count</td>
  </tr>
EOL
  } >> $summary_table
}

unit_tables() {
  # Combine All Tables
  {
    echo "<table class='mx-3 my-3'>"
    echo "    <tr>"
    echo "        <th>Module</th>"
    echo "        <th>Issues</th>"
    echo "    </tr>"
    cat $summary_table
    echo "</table>"
    echo "<br/>"
    cat $details_file
  } > $report_file
}

start "$@"; exit

#
#
##!/usr/bin/env bash
#
#pmd_config_path="config/scanner/pmd_config.xml"
#ignored_modules=(
#  "destructiveChanges"
#)
#output_directory="output"
#( mkdir -p $output_directory )
#
#do_scan() {
#  for module in src/*; do
#    module_name=${module##*/}
#    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
#      module_directory="$output_directory"/"$module_name"
#      ( mkdir -p "$module_directory" )
#      set_report_output "all-engines" "xml"
#      run_scanner "default" "junit"
##      set_report_output "all-engines" "html"
##      run_scanner "default" "html"
##
##      set_report_output "pmd" "xml"
##      run_scanner "pmd" "junit"
##      set_report_output "pmd" "html"
##      run_scanner "pmd" "html"
#    fi
#  done
#}
#
#set_report_output() {
#  report_name=$1-"$module_name"-$(date +"%Y-%m-%d")-$(date +"%H-%M-%S").$2
#  report_output_path="$module_directory"/"$report_name"
#}
#
#run_scanner() {
#  scanner_config="--target $module --format $2 --outfile "$report_output_path""
#  if [[ $1 == *"pmd"* ]]; then
#    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
#  fi
#  sf scanner run $scanner_config
#}
#
##set_report_output() {
##  report_name=$1-"$module_name"-$(date +"%Y-%m-%d")-$(date +"%H-%M-%S").$2
##  report_output_path="$module_directory"/"$report_name"
##}
##
##run_scanner() {
##  scanner_config="--target src/$module_name --format $2 --outfile "$report_output_path""
##  if [[ $1 == *"pmd"* ]]; then
##    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
##  fi
##  sf scanner run $scanner_config
##}
##
##module_name=$1
##if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
##  module_directory="$output_directory"/"$module_name"
##  ( mkdir -p "$module_directory" )
##  set_report_output "all-engines" "xml"
##  run_scanner "default" "junit"
##fi
#
#git config --global --add safe.directory "*"
##echo "output_directory=$output_directory" >> "$GITHUB_OUTPUT"
#
#do_scan "$@"; exit