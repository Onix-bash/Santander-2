#!/bin/bash

test_level_name=$1    # Test level from inputs
apex_unit_tests=$2    # Apex Unit tests from inputs (space-separated)

# Default test level
test_level=""
specified_tests=""

# Convert space-separated string to an array
IFS=' ' read -r -a array_apex_unit_tests <<< "$apex_unit_tests"

# Determine test level based on input
case $test_level_name in
  RunAllTestsInOrg)
    test_level="$test_level_name"
    ;;
  RunLocalTests) # All local Apex Unit tests from src except application-logging modules tests
    if [ "$IS_RELEASE_BRANCH" = "true" ]; then
      test_level="$test_level_name"
    else
      chmod +x ./devops-scripts/getTestClasses.sh
      IFS=' ' read -r -a testClasses <<< "$(./devops-scripts/getTestClasses.sh)"
      test_level="RunSpecifiedTests"
      specified_tests="${testClasses[*]}"
    fi
    ;;
  RunSpecifiedTests)
    # Ensure that a list of specific tests is provided
    if [ ${#array_apex_unit_tests[@]} -eq 0 ]; then
      echo "Error: No tests specified for RunSpecifiedTests"
      exit 1
    else
      test_level="$test_level_name"
      specified_tests="${array_apex_unit_tests[*]}"
    fi
    ;;
  *)
    test_level="NoTestRun"
    ;;
esac

echo "TEST_LEVEL=$test_level" >> $GITHUB_ENV
echo "SPECIFIED_TESTS=$specified_tests" >> $GITHUB_ENV