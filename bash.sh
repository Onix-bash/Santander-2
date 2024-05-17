#!/usr/bin/env bash

pmd_config_path="config/scanner/pmd_config.xml"
ignored_modules=(
  "destructiveChanges"
)
output_directory="output"
( mkdir -p $output_directory )

report_file="$output_directory/report.html"

do_scan() {
  for module in src/*; do
    module_name=${module##*/}
    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
      module_directory="$output_directory"/"$module_name"
      ( mkdir -p "$module_directory" )

#      set_report_output "all-engines" "xml"
#            run_scanner "default" "junit"
#            set_report_output "all-engines" "html"
#            run_scanner "default" "html"
#
#            set_report_output "pmd" "xml"
#            run_scanner "pmd" "junit"
#            set_report_output "pmd" "html"
#            run_scanner "pmd" "html"

            set_report_output "all-engines" "csv"
            run_scanner "default" "csv"
            csv_file="$report_output_path"

            set_report_output "pmd" "csv"
            run_scanner "pmd" "csv"
            run_markdown_html "$module_name" "$csv_file"
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

run_markdown_html() {
  local module_name=$1
  local csv_file=$2

  # Read CSV data from file
  csv_data=$(< "$csv_file")

  # Calculate the number of failed entries (rows)
  fail_count=$(echo "$csv_data" | awk -F',' 'NR > 1 {count++} END {print count}')

  # Write the initial HTML and table headers
  {
    cat <<EOL
<details><summary>$module_name (Failed: $fail_count)</summary>
    <table border="1">
    <tr>
        <th>Threshold</th>
        <th>Component Name</th>
        <th>Text</th>
    </tr>
    <tr>
        <td colspan="3" align="center">$module_name</td>
    </tr>
EOL

    # Process CSV data to generate table rows
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

      # Print table row
      printf "    <tr>\n"
      printf "        <td>%s</td>\n", threshold
      printf "        <td>%s</td>\n", component
      printf "        <td>%s\n", description
      printf "            <br/>Category: %s - %s\n", category, rule
      printf "            <br/>File: %s\n", file
      printf "            <br/>Line: %s\n", line
      printf "            <br/>Column: %s\n", column
      printf "            <br/><a href=\"%s\" title=\"%s\">%s</a></td>\n", url, rule, rule
      printf "    </tr>\n"
    }'

    # Close the table and details tags
    cat <<EOL
    </table>
</details>
EOL
  } >> "$report_file"
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
