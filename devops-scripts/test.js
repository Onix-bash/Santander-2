const argv = require('yargs-parser')(process.argv.slice(2))
const {execSync} = require('child_process');
console.log(argv.baseBranch)
const GITHUB_HEAD_REF = process.env.GITHUB_HEAD_REF;
const GITHUB_BASE_REF = process.env.GITHUB_BASE_REF;
console.log(GITHUB_HEAD_REF,GITHUB_BASE_REF)

const GITHUB_BASE_BRANCH = argv.baseBranch ? argv.baseBranch : `origin/${GITHUB_BASE_REF}`;
const GITHUB_CURRENT_BRANCH = argv.baseBranch ? 'origin' : `origin/${GITHUB_HEAD_REF}`;

execSync('git fetch origin');
        const gitDiff = execSync(`git diff --name-only ${GITHUB_BASE_BRANCH}...${GITHUB_CURRENT_BRANCH}`)
            .toString()
            .split('\n')
            .map((filename => filename.split('/').slice(-1).join()));

        console.log(gitDiff);