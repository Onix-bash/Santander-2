#!/bin/bash

# Get Test Classes
chmod +x ./devops-scripts/getTestClasses.sh
IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"

# Get Test Results
mkdir -p coverage-results
sf apex run test --code-coverage --detailed-coverage --output-dir coverage-results  --wait 10 --target-org CI-Org --test-level RunSpecifiedTests --tests "${testClasses[@]}"
json_report=$(cat coverage-results/test-result-codecoverage.json)

test_run_id=$(cat coverage-results/test-run-id.txt | tr -d '\n')
json_result_outcome="coverage-results/test-result-$test_run_id.json"

# Get Failed Test
is_failed=false
jq -c '.tests[]' "$json_result_outcome" > all_tests.json

while read -r test; do
    outcome=$(echo "$test" | jq -r '.Outcome')
    test_name=$(echo "$test" | jq -r '.ApexClass.Name')

    if [ "$outcome" == "Fail" ]; then
        echo "$test_name failed"
        is_failed=true
    fi
done < all_tests.json

start() {
  # Get Changed Classes
  git config --global --add safe.directory "*"
  source_to_check_changes="origin/$GITHUB_BASE_REF"
  current="origin/$GITHUB_HEAD_REF"
  git_diff=$(git diff --name-only $source_to_check_changes...$current | grep '\.cls$' | grep -v 'Test\.cls$' | sed 's|^|src/|')

  # Compare with UNIT_TEST_MIN_COVERAGE and UNIT_TEST_IGNORE_CLASSES
  while IFS= read -r class_file; do
    apex_class_name=$(basename "$class_file" .cls)
    coverage=$(get_coverage "$apex_class_name")

    if [ -n "$coverage" ]; then
      if [ "$coverage" -lt "$UNIT_TEST_MIN_COVERAGE" ]; then
        IFS=$'\n' read -r -d '' -a IGNORE_CLASSES_ARRAY <<< "$(echo "$UNIT_TEST_IGNORE_CLASSES" | sed '/^\s*$/d' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        ignore_class=false
        for ignore_class_name in "${IGNORE_CLASSES_ARRAY[@]}"; do
          if [ "$ignore_class_name" == "$apex_class_name" ]; then
            ignore_class=true
            break
          fi
        done
        if ! $ignore_class; then
          echo "'$class_file' has $coverage% coverage, it should be $UNIT_TEST_MIN_COVERAGE%"
          exit 1
        fi	  
      fi
    fi
  done <<< "$git_diff"

  # Handle Error
    if $is_failed; then
        echo "Failed tests were detected"
        exit 1
    fi
}

# Get Classes' Coverage
get_coverage() {
  class_name=$1
  echo "$json_report" | jq -r --arg class_name "$class_name" '.[] | select(.name == $class_name) | .coveredPercent'
}

start "$@"; exit