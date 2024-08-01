#!/bin/bash
changed_files=$1
echo "Pull Request Number: $PR_NUMBER" >> error_info.txt
echo "Pull Request Title: $PR_TITLE" >> error_info.txt
echo "Pull Request Link: $PR_LINK" >> error_info.txt
echo "Head Ref: $GITHUB_HEAD_REF" >> error_info.txt
echo "Base Ref: $GITHUB_BASE_REF" >> error_info.txt
echo "Repository: $GITHUB_REPOSITORY" >> error_info.txt
echo "Run ID: $GITHUB_RUN_ID" >> error_info.txt
echo "Edited Modules: $changed_files" >> error_info.txt # Example file path
echo "Show file"
cat error_info.txt
# Read the file content to a variable
#            COMMENTS=$(cat error_info.txt)
#            sf data create record --sobject Log__c --values "OrganizationEnvironmentType__c='Scratch Org' Comments__c='$COMMENTS'"