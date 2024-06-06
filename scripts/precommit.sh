#!/bin/sh
FILES=$(git diff --cached --name-only --diff-filter=ACMR | sed 's| |\\ |g')
[ -z "$FILES" ] && exit 0

if [ -z "$FILES" ]; then
    exit 0
fi

echo "Running prettier"
npm run prettier -- $FILES

# Add back the modified/prettified files to staging
echo "$FILES" | xargs git add

exit 0