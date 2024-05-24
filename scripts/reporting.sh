#!/usr/bin/env bash

pmd_config_path="config/scanner/pmd_config.xml"
ignored_modules=(
  "destructiveChanges"
)

# Create temporary files
output_directory="output"
mkdir -p "$output_directory"

scanner_details="$output_directory/scanner_details.html"
scanner_summary="$output_directory/scanner_summary.html"
scanner_results="$output_directory/scanner_results.html"

# Setup Environment to be used with Metadata Links
#github_repository=$(git config --get remote.origin.url | sed 's/\.git$//')
#github_branch=$(git branch | grep "*" | sed 's/* //')
github_repository="${GITHUB_REPOSITORY}"
cat ${GIT_BRANCH}
github_branch="${GIT_BRANCH#refs/heads/}"
start() {
  # Run Scanner
  for module in src/*; do
    module_name=${module##*/}
    if ! [[ ${ignored_modules[*]} =~ (^|[[:space:]])"$module_name"($|[[:space:]]) ]]; then
      # Create Module directory
      module_directory="$output_directory"/"$module_name"
      mkdir -p "$module_directory"

      # Run Scanner in CSV for Summary Tab and in HTML type for Storing as Artifacts
      run_scanner "html"
      run_scanner "csv"
      default_csv_file="$report_output_path"
      show_scanner_results "$module_name" "$default_csv_file"
    fi
  done

  unit_tables
}

# Run Scanner using All Engines
run_scanner() {
  report_name="all-engines-$module_name-$(date +"%Y-%m-%d-%H-%M-%S").$1"
  report_output_path="$module_directory/$report_name"

  sf scanner run --target $module --format $1 --pmdconfig $pmd_config_path --outfile $report_output_path
}

# Show Scanner Results on the Job Summary page (from CSV into GIT Markdown)
show_scanner_results() {
  local module_name=$1
  local csv_file=$2

  # Read CSV data from file
  csv_data=$(< "$csv_file")

  # Calculate the number of failed entries (rows)
  local fail_count=$(awk 'NR > 1 { count++ } END { print count+0 }' "$csv_file")
  if [ "$fail_count" -eq 0 ]; then
     return
  fi

  # Write the module's detailed report
  {
    cat <<EOL
<details id="$module_name" class="mx-3"><summary>$module_name</summary>
<p></p>
<table>
<tr>
  <th>Threshold</th>
  <th>Component Name</th>
  <th>Description</th>
</tr>
EOL

# Parse CSV into GIT Markdown
    echo "$csv_data" | awk -F',' -v repo="$github_repository" -v branch="$github_branch" 'NR > 1 {
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

      # Extract file path starting from "src"
      src_index = index(file, "src/")
      if (src_index > 0) {
       file_path = substr(file, src_index)
      } else {
        file_path = file
      }

      github_link = "https://github.com/" repo "/blob/" branch "/" file_path

      # Print Table Row
      printf "    <tr>\n"
      printf "        <td>%s</td>\n", threshold
      printf "        <td><a href=\"%s\" target=\"_blank\">%s</a></td>\n", github_link, component
      printf "        <td>%s\n", description
      printf "            <br/>Category: %s - %s\n", category, rule
      printf "            <br/>File: %s\n", file
      printf "            <br/>Line: %s\n", line
      printf "            <br/>Column: %s\n", column
      printf "            <br/><a href=\"%s\" title=\"%s\" target=\"_blank\">%s</a></td>\n", url, rule, rule
      printf "    </tr>\n"
    }'

    cat <<EOL
    </table>
    </details>
EOL
  } >> "$scanner_details"

  {
    cat <<EOL
  <tr>
    <td><a href="#user-content-$module_name" title="$module_name">$module_name</a></td>
    <td>$fail_count</td>
  </tr>
EOL
  } >> $scanner_summary
}

unit_tables() {
  # Combine All Tables
  {
    echo "<table class='mx-3 my-3'>"
    echo "    <tr>"
    echo "        <th>Module</th>"
    echo "        <th>Issues</th>"
    echo "    </tr>"
    cat $scanner_summary
    echo "</table>"
    echo "<br/>"
    cat $scanner_details
  } > $scanner_results
}

start "$@"; exit