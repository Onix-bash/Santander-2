const { execSync } = require('child_process');
const fs = require('fs');
const { Octokit } = require("@octokit/rest");
const github = require('@actions/github');

const token = process.env.GITHUB_TOKEN;
const octokit = new Octokit({ auth: token });

const PULL_REQUEST_HEAD_REF = process.env.PULL_REQUEST_HEAD_REF;
const PULL_REQUEST_BASE_REF = process.env.PULL_REQUEST_BASE_REF;

const pmdConfigPath = "config/scanner/pmd_config.xml";
const eslintConfigPath = "config/scanner/.eslintrc.json";
const outputDirectory = "output";
const reportOutputPath = `${outputDirectory}/report.json`;

execSync(`git config --global --add safe.directory /__w/Santander-2/Santander-2`);
execSync(`mkdir -p ${outputDirectory}`);
execSync(`git fetch origin ${PULL_REQUEST_HEAD_REF}`);
execSync(`git fetch origin ${PULL_REQUEST_BASE_REF}`);
const gitDiff = execSync(`git diff --name-only origin/${PULL_REQUEST_BASE_REF}..origin/${PULL_REQUEST_HEAD_REF}`).toString();
const srcFiles = gitDiff.split('\n').filter(file => file.startsWith('src/')).join(',');
execSync(`sf scanner run --target "${srcFiles}" --format json --pmdconfig "${pmdConfigPath}" --eslintconfig "${eslintConfigPath}" --outfile "${reportOutputPath}"`);

const report = JSON.parse(fs.readFileSync(reportOutputPath, 'utf-8'));
const prNumber = github.context.payload.pull_request.number;
const repoOwner = github.context.repo.owner;
const repoName = github.context.repo.repo;

octokit.pulls.listFiles({
    owner: repoOwner,
    repo: repoName,
    pull_number: prNumber
}).then(filesResponse => {
    const files = filesResponse.data;
    const fileChanges = {};
    files.forEach(file => {
        fileChanges[file.filename] = file;
    });

    report.forEach(file => {
        const fileName = file.fileName.replace('/__w/Santander-2/Santander-2/', '');
        const violations = file.violations;

        if (fileChanges[fileName]) {
            const currentFile = fileChanges[fileName];
            violations.forEach(async violation => {
                const rulePath = violation.url ? violation.url : '';
                const message = `<table role="table"><thead><tr><th>Attribute</th><th>Value</th></tr></thead><tbody><tr><td>Engine</td><td>${file.engine}</td></tr>
                         <tr><td>Category</td><td>${violation.category}</td></tr>
                         <tr><td>Rule</td><td>${violation.ruleName}</td></tr>
                         <tr><td>Line</td><td>${violation.line}</td></tr>
                         <tr><td>Severity</td><td>${violation.severity}</td></tr>
                         <tr><td>Message</td><td><a href=${rulePath} rel="nofollow">${violation.message}</a></td></tr>
                         <tr><td>File</td><td><a href=${currentFile.filename}>${currentFile.filename}</a></td></tr></tbody></table>`;

                const patchLines = currentFile.patch ? currentFile.patch.split('\n') : [];
                let position = null;
                let diffLine = 0;
                let originalLine = 0;
                let inHunk = false;
                for (let i = 0; i < patchLines.length; i++) {
                    const line = patchLines[i];
                    const hunkMatch = /^@@ -(\d+),\d+ \+(\d+),\d+ @@/.exec(line);
                    if (hunkMatch) {
                        originalLine = parseInt(hunkMatch[1], 10);
                        diffLine = parseInt(hunkMatch[2], 10) - 1;
                        inHunk = true;
                    } else if (inHunk) {
                        if (line.startsWith('+') && !line.startsWith('+++')) {
                            diffLine++;
                            if (diffLine === violation.line) {
                                position = i + 1;
                                break;
                            }
                        } else if (!line.startsWith('-')) {
                            originalLine++;
                        }
                    }
                }

                if (position !== null) {
                    try {
                        await octokit.pulls.createReviewComment({
                            owner: repoOwner,
                            repo: repoName,
                            pull_number: prNumber,
                            body: message,
                            commit_id: github.context.payload.pull_request.head.sha,
                            path: fileName,
                            position: position,
                            side: 'RIGHT'
                        });
                    } catch (error) {
                        console.log(`Error: ${error.message}`);
                    }
                } else {
                    try {
                        await octokit.pulls.createReviewComment({
                            owner: repoOwner,
                            repo: repoName,
                            pull_number: prNumber,
                            body: message,
                            commit_id: github.context.payload.pull_request.head.sha,
                            path: fileName,
                            side: 'RIGHT',
                            subject_type: 'file'
                        });
                    } catch (error) {
                        console.log(`Error: ${error.message}`);
                    }
                }
            });
        }
    });
}).catch(error => {
    console.log(`Error: ${error.message}`);
});
