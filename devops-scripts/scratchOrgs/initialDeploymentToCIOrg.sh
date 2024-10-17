#!/bin/bash
set -e

# script creates a scratch org with all dependent packages, licenses, source code deployed and test users created
org_alias="$1"
if [ -z "$org_alias" ]; then
  org_alias="source-org"
fi

# Remove entries about BRE engine from .forceignore so they are being initially deployed
sed -i -e "s/expressionSetDefinition//g" .forceignore
sed -i -e "s/decisionMatrixDefinition//g" .forceignore

export API_MORTGAGE_ONBOARDING_PASSTHRU=DEV
# Temporary fix & will be automated correctly in scope of ticket (MAXSF-6759)
sf project deploy start --source-dir ./devops-scripts/scratchOrgs/flows --ignore-conflicts --target-org "$org_alias"
sf project reset tracking --target-org "$org_alias" --no-prompt
sf project deploy start --source-dir ./src --ignore-conflicts --target-org "$org_alias"

sf org assign permset --name PSG004_Homes_BrokerPortalAdmin --target-org "$org_alias"
