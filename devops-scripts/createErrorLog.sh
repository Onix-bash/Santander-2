#!/bin/bash

echo "Pull Request Title: $PR_TITLE" >> error_info.txt
echo "Pull Request Number: $PR_NUMBER" >> error_info.txt
echo "Pull Request: $PR_LINK" >> error_info.txt
echo "Head Ref: $GITHUB_SERVER/$GITHUB_REPOSITORY/tree/$GITHUB_HEAD_REF" >> error_info.txt
echo "Base Ref: $GITHUB_SERVER/$GITHUB_REPOSITORY/tree/$GITHUB_BASE_REF" >> error_info.txt
echo "Repository: $GITHUB_SERVER/$GITHUB_REPOSITORY" >> error_info.txt
echo "Changed files: $PR_LINK/files" >> error_info.txt

# Read the file content to a variable
COMMENTS=$(cat error_info.txt)
sf data create record --sobject Log__c --values "OrganizationEnvironmentType__c='Scratch Org' Comments__c='$COMMENTS'"
