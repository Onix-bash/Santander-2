#!/bin/bash
testClasses=$(find ./src -name "*.cls" ! -path "./src/application-logging/*" -exec grep -l -i "@IsTest" {} \; | xargs -n1 basename | sed 's/.cls//' | paste -sd " " -)
cd ..
echo ${testClasses}

