#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

target_org="target-org"
if [ -n "$1" ]; then
  target_org=$1
fi
echo "Running QMS download for org: $target_org"

sf apex run --file ./devops-scripts/qms/stampExternalIdsScript.apex --target-org "$target_org"

sf data export tree --plan --target-org "$target_org" --output-dir ./data/qms --query "SELECT Name, HMExternalId__c, HMAudience__c, HMIsActive__c, HMJourney__c, HMVersionName__c FROM HMQuestionVersion__c ORDER BY Name"
sf data export tree --plan --target-org "$target_org" --output-dir ./data/qms --query "SELECT Name, HMDisplayName__c, HMSection__c, HMSectionVariant__c, HMExternalId__c FROM HMQuestionSection__c ORDER BY Name"
sf data export tree --plan --target-org "$target_org" --output-dir ./data/qms --query "SELECT Name, HMDependentQuestionExternalId__c, HMQuestionType__c, HMDependentValue__c, HMRegExPattern__c, HMRegExMessage__c, HMDataModelObject__c, HMDataModelField__c, HMDataModelType__c, HMQuestion__c, HMNonQMSDependentFieldsAndValues__c, HMDataModelFieldSecond__c, HMDataModelFieldValues__c, HMExternalId__c, HMQuestionVariant__c, HMSubText__c FROM HMQuestion__c ORDER BY Name"
sf data export tree --target-org "$target_org" --output-dir ./data/qms --query "SELECT Name, HMQuestionText__c, HMHelpText__c, HMOrder__c, HMPlaceholder__c, HMDefaultValue__c, HMIsQuestionDisabled__c, HMExternalQuestionId__c, HMExternalVersionId__c, HMExternalSectionId__c FROM HMQuestionJunction__c ORDER BY Name"

echo "QMS data downloaded successfully"