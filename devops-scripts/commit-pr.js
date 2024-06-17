const fs = require('fs');
import { getOctokit } from '@actions/github';
const github = require("@actions/github");

const githubToken = process.env.GITHUB_TOKEN;
const octokit = getOctokit(githubToken);

const outputDirectory = "output";
const reportOutputPath = `${outputDirectory}/report.json`;

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

                const position = getLineNumberFromDiff(currentFile.patch)

                if (position !== null) {
                    try {
                        await octokit.rest.pulls.createReviewComment({
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
                        await octokit.rest.pulls.createReviewComment({
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

// Helper function to extract the correct line number from the diff hunk
function getLineNumberFromDiff(diffHunk) {
    const lines = diffHunk ? diffHunk.split('\n') : [];
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('+') && !lines[i].startsWith('+++')) {
            return i + 1;
        }
    }
    return 1; // Default to the first line if no added lines are found
}
