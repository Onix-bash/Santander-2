#!/bin/bash
set -e
if [ -z "$SFDXAUTHURL" ]; then
  echo "SFDX auth url not provided, closing the job";
  exit 1;
else
  extra_options=$1
  echo "--- Starting authentication"
  echo "$SFDXAUTHURL" > ./sfdxAuthUrl.txt
  if [ "SKIP_ORG_INTERACTION" = "true" ]; then
    echo "Org interaction has been skipped because of setup: SKIP_ORG_INTERACTION = true"
  else
    sf org login sfdx-url --sfdx-url-file ./sfdxAuthUrl.txt $extra_options
    sf org list
  fi
fi
