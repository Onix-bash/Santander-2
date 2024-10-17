#!/bin/bash
set -e

# script creates a scratch org with all dependent packages, licenses, source code deployed and test users created
org_alias="$1"
if [ -z "$org_alias" ]; then
  org_alias="source-org"
fi
DURATION_DAYS="$2"
if [ -z "$DURATION_DAYS" ]; then
  DURATION_DAYS=14
fi
admin_email="$3"

release_name="$4"
release=""
if [ "$release_name" != "current" ]; then
  release="--release $release_name"
fi

sf org create scratch --definition-file config/project-scratch-def.json --alias "$org_alias" --set-default -w 20 --duration-days $DURATION_DAYS --admin-email "$admin_email" $release --no-track-source
sf org list

orgInfo=$(sf org display --verbose --json --target-org "$org_alias" | sed s/\\\\n//g)
echo "Org Info: $orgInfo"
export SCRATCH_AUTHURL
SCRATCH_AUTHURL=$(echo "$orgInfo" | jq -r '.result.sfdxAuthUrl')
echo "SfdxAuthUrl: $SCRATCH_AUTHURL"

org_id=$(echo "$orgInfo" | jq -r '.result.id')
echo "org_id=$org_id" >> "$GITHUB_OUTPUT"

sf org assign permset --name Mortgage --target-org "$org_alias"
sf org assign permset --name DocumentChecklist --target-org "$org_alias"

sed -i -e "s/PING_PASSWORD/$PING_CRT_PASSWORD/g" ./config/browserforce/scratch-org.json
sf browserforce apply --definitionfile ./config/browserforce/scratch-org.json --target-org "$org_alias"

echo "Install Financial Services Cloud..."
sf force package install --package 04tHn000001eEAL -w 20 --target-org "$org_alias"
echo "Install FSC extensions package..."
sf force package install --package 04t1E000001Iql5 -w 20 --target-org "$org_alias"
echo "Install Lightning Flow for FSC package..."
sf force package install --package 04t3i000000jP1g -w 20 --target-org "$org_alias"
echo "Install Omnistudio package..."
sf force package install --no-prompt --package 04t4W0000038bna -w 20 --target-org "$org_alias"


