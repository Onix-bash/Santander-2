#!/bin/bash

# Script cancels the Validate/Deployment Job in Salesforce if the "Cancel Workflow" button was pressed

echo "--- Job Cancellation is started ---"
sf project deploy cancel --job-id $1