const argv = require('yargs-parser')(process.argv.slice(2))
const {execSync} = require('child_process');
console.log(argv.baseBranch)

const sourceToCheckChanges = argv.baseBranch ? argv.baseBranch : `origin/${process.env.GITHUB_BASE_REF}`;
const currentBranch = `origin/${process.env.GITHUB_HEAD_REF}`;


console.log(sourceToCheckChanges,currentBranch )
execSync('git fetch origin');
        const gitDiff = execSync(`git diff --name-only ${sourceToCheckChanges}...${currentBranch}`)
            .toString()
            .split('\n')
            .map((filename => filename.split('/').slice(-1).join()));

        console.log(gitDiff);