#!/bin/bash
set -e
REQUIRED_FLOW_COVERAGE=$1
echo "To make sure that code coverage calculation is accurate run your unit tests before"
flows_with_coverage=$(sf data query --query "SELECT count_distinct(FlowVersionId) flow_count FROM FlowTestCoverage" --use-tooling-api --json | jq '.result.records[].flow_count')
active_flows_without_coverage=$(sf data query --query "SELECT count_distinct(Id) flow_count FROM Flow WHERE Status = 'Active' AND Id NOT IN (SELECT FlowVersionId FROM FlowTestCoverage )" --use-tooling-api --json | jq '.result.records[].flow_count')
flows_with_no_coverage=$(sf data query --query "SELECT Definition.DeveloperName FROM Flow WHERE Status = 'Active' AND (ProcessType = 'RecordBeforeSave' OR ProcessType = 'RecordBeforeDelete' OR ProcessType = 'RecordAfterSave') AND Id NOT IN (SELECT FlowVersionId FROM FlowTestCoverage)" --use-tooling-api --json | jq '.result.records[]')
total_coverage=$((flows_with_coverage / (flows_with_coverage + active_flows_without_coverage)))
echo "Total Flow test coverage result: $total_coverage%"
echo "Record triggered flows that are Active and has no coverage:"
echo $flows_with_no_coverage
if [ -n "$REQUIRED_FLOW_COVERAGE" ] && [ "$total_coverage" -lt "$REQUIRED_FLOW_COVERAGE" ] ; then
  echo "Error: Flow test coverage doesnt meet required minimum: $REQUIRED_FLOW_COVERAGE";
  exit 1;
fi

