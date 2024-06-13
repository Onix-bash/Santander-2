pmd_config_path="config/scanner/pmd_config.xml"
source_to_check_changes="origin/develop"
git config --global --add safe.directory /__w/Santander-2/Santander-2
output_directory="output"
mkdir -p "$output_directory"

git fetch origin "$PULL_REQUEST_HEAD_REF"
git fetch origin "$PULL_REQUEST_BASE_REF"

echo "PULL_REQUEST_HEAD_REF: '$PULL_REQUEST_HEAD_REF'"
git_diff=git diff --name-only $PULL_REQUEST_BASE_REF..$PULL_REQUEST_HEAD_REF

echo "git_diff: '$git_diff'"

sf scanner run --target "$git_diff" --format json --pmdconfig "$pmd_config_path" --eslintconfig "$eslint_config_path" --outfile output_directory/report.json

cat output_directory/report.json