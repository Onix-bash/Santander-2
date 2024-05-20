#!/usr/bin/env bash

pmd_config_path="config/scanner/pmd_config.xml"
ignored_modules=(
  "destructiveChanges"
)
output_directory="output"
mkdir -p "$output_directory"

report_file="$output_directory/report.html"

# Create temporary files
details_file="$output_directory/details_file.html"
summary_table="$output_directory/summary_table.html"

do_scan() {
  for module in src/*; do
    module_name=${module##*/}
    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
      module_directory="$output_directory"/"$module_name"
      mkdir -p "$module_directory"

      set_report_output "all-engines" "csv"
      run_scanner "default" "csv"
      csv_file="$report_output_path"

      set_report_output "pmd" "csv"
      run_scanner "pmd" "csv"
      create_details_report "$module_name" "$csv_file"
    fi
  done

  unit_tables
}

set_report_output() {
  report_name="$1-$module_name-$(date +"%Y-%m-%d-%H-%M-%S").$2"
  report_output_path="$module_directory/$report_name"
}

run_scanner() {
  local scanner_config="--target $module --format $2 --outfile $report_output_path"
  if [[ $1 == "pmd" ]]; then
    scanner_config+=" --engine pmd --pmdconfig $pmd_config_path"
  fi
  sf scanner run $scanner_config
}

create_details_report() {
  local module_name=$1
  local csv_file=$2

  # Read CSV data from file
  csv_data=$(< "$csv_file")

  # Calculate the number of failed entries (rows)
  fail_count=$(echo "$csv_data" | awk -F',' 'NR > 1 {count++} END {print count}')

  # Write the module's detailed report
  {
    cat <<EOL
<details id="$module_name" class="mx-3"><summary>$module_name</summary>
<p></p>
<table>
<tr>
  <th>Threshold</th>
  <th>Component Name</th>
  <th>Text</th>
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
      printf "            <br/><a href=\"%s\" target=\"_blank\" title=\"%s\">%s</a></td>\n", url, rule, rule
      printf "    </tr>\n"
    }'

    cat <<EOL
</table>
</details>
EOL
  } >> "$details_file"

  # Append module info to the summary table
  {
    cat <<EOL
<tr>
  <td><a href="#user-content-$module_name" title="$module_name">$module_name</a></td>
  <td>$fail_count</td>
</tr>
EOL
  } >> $summary_table
}

unit_tables() {
  # Combine two tables into final report file
  {
    echo "<table class='mx-3 my-3'>"
    echo "    <tr>"
    echo "        <th>Module</th>"
    echo "        <th>Failed</th>"
    echo "    </tr>"
    cat $summary_table
    echo "</table>"
    echo "<br/>"
    cat $details_file
  } > $report_file

  # Delete temporary files
  rm $summary_table $details_file
}

echo "output_directory=$output_directory" >> "$GITHUB_OUTPUT"
do_scan "$@"; exit
