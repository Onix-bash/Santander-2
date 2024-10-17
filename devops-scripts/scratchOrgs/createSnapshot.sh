#!/bin/bash
set -e
# script creates a snapshot of the source org
# it requires two parameters: source org alias and snapshot alias
# example: sh ./devops-scripts/createSnapshot.sh sourceOrg snapshotAlias
# WARNING: if snapshot with the same name already exists, it will be deleted


if [ -z "$1" ]; then
  echo "Please provide Source Org Alias ";
  exit 1;
fi
if [ -z "$2" ]; then
  echo "Please provide Snapshot name";
  exit 1;
fi
# delete the snapshot if it already exists
json=$(sf org list snapshot --json)
does_snapshot_exists=$(echo $json | jq -c "any(.result[]; .SnapshotName == \"$2\")")
if [ "$does_snapshot_exists" = true ]; then
  sf org delete snapshot --snapshot "$2" --no-prompt
fi

# create a new snapshot and watch creation progress
sf org create snapshot --source-org "$1" --name "$2"
snapshotStatus="InProgress"
while [ $snapshotStatus = "InProgress" ]
do
  snapshotStatus=$(sf org get snapshot --snapshot $2 --json | jq -r '.result.Status')
  echo Snapshot creation status - "$snapshotStatus"
  sleep 10
done
echo "Snapshot creation ended up with status - $snapshotStatus"

# Snapshot creation takes around 7-8 minutes