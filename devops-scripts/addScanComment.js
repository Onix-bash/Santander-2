const fs = require('fs');
const core = require('@actions/core');
const github = require('@actions/github');
const octokit = github.getOctokit(process.env.GITHUB_TOKEN)
const context = github.context;

async function run() {
    const prNumber = context.payload.pull_request.number;
    const repoOwner = context.repo.owner;
    const repoName = context.repo.repo;

    try {
        // Read the JSON report
        const report = JSON.parse(fs.readFileSync('output/report.json', 'utf-8'));
        console.log("report: ", report[0].violations);


        // Get list of files changed in the PR
        const files = await octokit.pulls.listFiles({
            owner: repoOwner,
            repo: repoName,
            pull_number: prNumber,
        });


        // Create a map of file changes
        const fileChanges = {};
        for (const file of files) {
            fileChanges[file.filename] = file;
        }

        for (const file of report) {
            const fileName = file.fileName.replace('/__w/Santander-2/Santander-2/', '');
            const violations = file.violations; // Access the violations array

            // Check if the file is part of the PR
            if (fileChanges[fileName]) {
                const currentFile = fileChanges[fileName];
                for (const violation of violations) {
                    console.log("violation: ", violation);
                    console.log("currentFile", currentFile);
                    const rulePath = violation.url ? violation.url : '';
                    const message = `<table role="table"><thead><tr><th>Attribute</th><th>Value</th></tr></thead><tbody><tr><td>Engine</td><td>${currentFile.engine}</td></tr>
              <tr>
              <td>Category</td>
              <td>${violation.category}</td>
              </tr>
              <tr>
              <td>Rule</td>
              <td>${violation.ruleName}</td>
              </tr>
              <tr>
              <td>Severity</td>
              <td>${violation.severity}</td>
              </tr>
              <tr>
              <td>Type</td>
              <td>Error</td>
              </tr>
              <tr>
              <td>Message</td>
              <td><a href=${rulePath} rel="nofollow">${violation.message}</a></td>
              </tr>
              <tr>
              <td>File</td>
              <td><a href=${currentFile.fileName}>${currentFile.fileName}</a></td>
              </tr>
              </tbody>
              </table>`;

                    // Determine the position in the diff
                    const patchLines = currentFile.patch.split('\n');
                    let position = null;
                    let addedLinesCount = 0;

                    for (let i = 0; i < patchLines.length; i++) {
                        const line = patchLines[i];
                        if (line.startsWith('+') && !line.startsWith('+++')) {
                            addedLinesCount++;
                        }
                        if (addedLinesCount === violation.line) {
                            position = i + 1; // GitHub's position is 1-based
                            break;
                        }
                    }

                    if (position !== null) {
                        await octokit.rest.pulls.createReviewComment({
                            owner: repoOwner,
                            repo: repoName,
                            pull_number: prNumber,
                            body: message,
                            commit_id: context.payload.pull_request.head.sha,
                            path: fileName,
                            position: position,
                            side: 'RIGHT'
                        });
                    }
                }
            }
        }
    } catch (error) {
        console.log(`Error: ${error.message}`);
        core.setFailed(error.message);
    }
}

run();
