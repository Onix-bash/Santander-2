const argv = require('yargs-parser')(process.argv.slice(2))
const {execSync} = require('child_process');

const GITHUB_HEAD_REF = process.env.GITHUB_HEAD_REF;
const GITHUB_BASE_REF = process.env.GITHUB_BASE_REF;
console.log('head', GITHUB_HEAD_REF.length,'base', GITHUB_BASE_REF)

const GITHUB_BASE_BRANCH = GITHUB_HEAD_REF.length ? `origin/${GITHUB_BASE_REF}` : 'HEAD^'
const GITHUB_CURRENT_BRANCH = GITHUB_BASE_REF.length ? `origin/${GITHUB_HEAD_REF}` : '';

execSync('git fetch origin');
        const gitDiff = execSync(`git diff --name-only ${GITHUB_BASE_BRANCH}`)
            .toString()
            .split('\n')
            .map((filename => filename.split('/').slice(-1).join()));

        console.log(gitDiff);