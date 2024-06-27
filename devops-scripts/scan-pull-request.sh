pmd_config_path="config/scanner/pmd_config.xml"
eslint_config_path="config/scanner/.eslintrc.json"
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "branch: '$current_branch'"

git config --global --add safe.directory /__w/Santander-2/Santander-2
output_directory="output"
mkdir -p "$output_directory"

git fetch origin "$PULL_REQUEST_HEAD_REF"
git fetch origin "$PULL_REQUEST_BASE_REF"
echo "src_diff_files: '$src_diff_files'"
echo "PULL_REQUEST_HEAD_REF: '$PULL_REQUEST_HEAD_REF'"
git_diff=$(git diff --name-only origin/$PULL_REQUEST_BASE_REF..origin/$PULL_REQUEST_HEAD_REF)
src_files=$(echo "$git_diff" | grep '^src/' | tr '\n' ',' | sed 's/,$//')
echo "Filtered files: $src_files"
echo "sf scanner run --target '$src_files' --format json --pmdconfig '$pmd_config_path' --eslintconfig '$eslint_config_path' --outfile '$report_output_path'"

report_output_path="$output_directory/report.json"
sf scanner run --target "$src_files" --format json --pmdconfig "$pmd_config_path" --eslintconfig "$eslint_config_path" --outfile $report_output_path

cat output/report.json