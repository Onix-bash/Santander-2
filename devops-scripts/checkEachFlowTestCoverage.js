const exec = require('@actions/exec');
const core = require('@actions/core');
const argv = require('yargs-parser')(process.argv.slice(2))

const QUERY =
    '"SELECT Id, FlowVersionId, FlowVersion.VersionNumber, NumElementsCovered, NumElementsNotCovered, FlowVersion.MasterLabel ' +
    'FROM FlowTestCoverage ' +
    'WHERE FlowVersion.Status = \'Active\'"';

let queryCommandParams = ['--json', '--use-tooling-api'];
if (argv.targetOrg) {
    queryCommandParams.push(`--target-org=${argv.targetOrg}`);
}
exec.getExecOutput(`sf data query --query ${QUERY}`, queryCommandParams, {silent: false})
    .then((result) => {
        JSON.parse(result.stdout).result.records.forEach(coverageInfo => {
            const flowName = coverageInfo.FlowVersion.MasterLabel;
            const allElementsCount = coverageInfo.NumElementsCovered + coverageInfo.NumElementsNotCovered;
            const calculatedCoverage = (coverageInfo.NumElementsCovered / allElementsCount) * 100;
            core.info(`Flow: ${flowName} has covered ${coverageInfo.NumElementsCovered}/${allElementsCount} of elements, coverage equals: ${calculatedCoverage}%`)
            if (argv.requiredCoverage && calculatedCoverage < argv.requiredCoverage) {
                core.setFailed(`Flow test coverage doesnt meet the required minimum: ${argv.requiredCoverage} \%`)
            }
        });
    });