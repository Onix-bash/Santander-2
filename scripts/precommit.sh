#!/bin/sh
FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '^src/' | sed 's| |\\ |g')

echo "Git diff files from ACMR filter: '$FILES'"

if [ -z "$FILES" ]; then
    exit 0
fi

echo "Running prettier"
npm run prettier:pre-commit --"$FILES"
echo "after prettier: '$FILES'"
# Add back the modified/prettified files to staging
echo "$FILES" | xargs git add

exit 0