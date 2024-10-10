const exec = require('@actions/exec');
const argv = require('yargs-parser')(process.argv.slice(2))

console.log('argv', argv);
const CURRENT_POOL_SIZE = argv.currentSize;
const DESIRED_POOL_SIZE = argv.desiredSize;

const numberOfOrgsToCreate = DESIRED_POOL_SIZE - CURRENT_POOL_SIZE;
const orgCreationJobs = [];
for (let i = 0; i < numberOfOrgsToCreate; i++) {
    orgCreationJobs.push(exec.getExecOutput('gh workflow run create-scratch-org.yml --field duration=3',[], {silent: false}));
}
Promise.all(orgCreationJobs)
    .then((results) => {
    results.forEach((result) => {
        console.log(result);
    })
    console.log('Orgs creation jobs has been started, orgs to be created: ', results.length);
}).finally(() => {
    exec.exec(`echo \"${orgCreationJobs.length} jobs have been started to reach desired pool size\" >> \"$GITHUB_STEP_SUMMARY\"`);
});
