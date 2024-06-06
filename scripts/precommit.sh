#!/bin/sh
FILES=$(git diff --cached --name-only --diff-filter=ACMR | sed 's| |\\ |g')
echo "start '$FILES'"
if [ -z "$FILES" ]; then
    exit 0
fi
echo "before '$FILES'"
echo "Running prettier"
npm run prettier -- $FILES
echo "after: '$FILES'"
# Add back the modified/prettified files to staging
echo "$FILES" | xargs git add

exit 0