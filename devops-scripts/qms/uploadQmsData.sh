#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

target_org="target-org"
if [ -n "$1" ]; then
  target_org=$1
fi
echo "Running QMS upload for org: $target_org"

sf apex run --file ./devops-scripts/qms/deleteExistingQMSRecords.apex --target-org "$target_org"

( cd ./data/qms ; sf data import tree --target-org "$target_org" --plan HMQuestionVersion__c-plan.json )
( cd ./data/qms ; sf data import tree --target-org "$target_org" --plan HMQuestionSection__c-plan.json )
( cd ./data/qms ; sf data import tree --target-org "$target_org" --plan HMQuestion__c-plan.json )

sf static-resource generate --name QMS_Junctions --type application/json --output-dir ./src/question-management-system/staticresources
cat data/qms/HMQuestionJunction__c.json > ./src/question-management-system/staticresources/QMS_Junctions.json

sf project deploy start --metadata StaticResource:QMS_Junctions --target-org "$target_org"

sf apex run --file ./devops-scripts/qms/linkQmsRecords.apex --target-org "$target_org"

#cleanup
sf project delete source --metadata StaticResource:QMS_Junctions --target-org "$target_org" --no-prompt
rm -f ./src/question-management-system/staticresources/QMS_Junctions.json
rm -f ./src/question-management-system/staticresources/QMS_Junctions.resource-meta.xml

echo "QMS data uploaded successfully"
