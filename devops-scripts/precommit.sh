#!/bin/sh
# Retrieving a list of files from /src with an ACMR filter staged for commiting.
FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '^src/' | sed 's| |\\ |g')

if [ -z "$FILES" ]; then
    exit 0
fi

echo "Running prettier"
#npm run prettier:pre-commit --"$FILES"
echo "$FILES" | xargs npx prettier --ignore-unknown --write

# Add back the modified/prettified files to staging
echo "$FILES" | xargs git add
exit 0