#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo " --- Creating a scratch org from snapshot"
# Updating snapshot name from configuration
sed -i -e "s/SNAPSHOT_NAME/$SNAPSHOT_NAME/g" ./config/project-snap-def.json

release_name="$4"
release=""
if [ "$release_name" != "current" ]; then
  release="--release $release_name"
fi

sf org create scratch --definition-file config/project-snap-def.json --wait 20  --duration-days 14 $release --set-default

# Inserting certificate to scratch org
sed -i -e "s/PING_PASSWORD/$PING_CRT_PASSWORD/g" ./config/browserforce/scratch-org.json
sf browserforce apply --definitionfile ./config/browserforce/scratch-org.json

sf project deploy start --source-dir ./src --ignore-conflicts
sf org generate password --complexity 3 --length 10
org_info=$(sf org display --verbose --json | sed 's/\\n/ /g' | jq)
echo "Org info: $org_info"
username=$(echo $org_info | jq -r '.result.username')
instanceUrl=$(echo $org_info | jq -r '.result.instanceUrl')
password=$(echo $org_info | jq -r '.result.password')

echo "Scratch Org created successfully :rocket:" >> "$GITHUB_STEP_SUMMARY"
echo "Authentication details:" >> "$GITHUB_STEP_SUMMARY"
echo "Username: $username" >> "$GITHUB_STEP_SUMMARY"
echo "Password: $password" >> "$GITHUB_STEP_SUMMARY"
echo "Org instance URL: $instanceUrl" >> "$GITHUB_STEP_SUMMARY"
