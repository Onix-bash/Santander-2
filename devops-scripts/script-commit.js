const fs = require('fs');

module.exports = async ({ github, context }) => {
    const prNumber = context.payload.pull_request.number;
    const repoOwner = context.repo.owner;
    const repoName = context.repo.repo;
    const branch = context.payload.pull_request.head.ref;
    const severity = process.env.SEVERITY;
    const fullRepoName = repoOwner + '/' + repoName;

    try {
        // Read the JSON report
        const report = JSON.parse(fs.readFileSync('output/report.json', 'utf-8'));
        // Get list of files changed in the PR
        const { data: files } = await github.rest.pulls.listFiles({
            owner: repoOwner,
            repo: repoName,
            pull_number: prNumber
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
                    if (violation.severity <= severity) {
                        const message = createTable(violation, file, fileName, fullRepoName, branch, 'file');

                        // Determine the position in the diff
                        const diffLines = getModifiedLines(currentFile.patch);
                        const subjectType = diffLines.includes(violation.line) ? 'line' : 'file'

                            console.log('diffLines', diffLines)
                            console.log('position',violation.line)
                            try {
                                await github.rest.pulls.createReviewComment({
                                    owner: repoOwner,
                                    repo: repoName,
                                    pull_number: prNumber,
                                    body: message,
                                    commit_id: context.payload.pull_request.head.sha,
                                    path: fileName,
                                    position: violation.line,
                                    side: 'RIGHT',
                                    subject_type: subjectType
                                });
                            } catch (error) {
                                console.log(`Error during commit creation: ${error.message}`);
                            }
                        // } else {
                        //     try {
                        //         await github.rest.pulls.createReviewComment({
                        //             owner: repoOwner,
                        //             repo: repoName,
                        //             pull_number: prNumber,
                        //             body: message,
                        //             commit_id: context.payload.pull_request.head.sha,
                        //             path: fileName,
                        //             side: 'RIGHT',
                        //             subject_type: 'file'
                        //         });
                        //     } catch (error) {
                        //         console.log(`Error: ${error.message}`);
                        //     }
                        // }
                    }
                }

            } else {
                let reviewComment = '';
                for (const violation of violations) {
                    if (violation.severity <= severity) {
                        reviewComment += '\n' + createTable(violation, file, fileName, fullRepoName, branch, 'pr');
                    }
                }
                if (reviewComment) {
                    try {
                        // Add comment
                        await github.rest.issues.createComment({
                            owner: repoOwner,
                            repo: repoName,
                            issue_number: prNumber,
                            body: reviewComment
                        });
                    } catch (error) {
                        console.log('error', error)
                    }
                }
            }
        }
    } catch (error) {
        console.log(`Error: ${error.message}`);
    }

    function getModifiedLines(diffHunk) {
        const lines = diffHunk ? diffHunk.split('\n') : [];
        const modifiedLines = [];
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('+') && !lines[i].startsWith('+++') || lines[i].startsWith('-') && !lines[i].startsWith('---')) {
                modifiedLines.push(i + 1); // Collect the line numbers of the modified lines
            }
        }
        console.log(modifiedLines)
        return modifiedLines;
    }

    // Helper function to extract the correct line number from the diff hunk
    function getLineNumberFromDiff(diffHunk) {
        const lines = diffHunk ? diffHunk.split('\n') : [];

        for (let i = 0; i < lines.length; i++) {
            if(lines[i].startsWith('+++')) {console.log(lines[i])}
            if(lines[i].startsWith('---')) {console.log(lines[i])}
            if(lines[i].startsWith('-')) {console.log(lines[i])}
            if (lines[i].startsWith('+') && !lines[i].startsWith('+++') || lines[i].startsWith('-') ) {
                return i + 1;
            }
        }
        return 0; // Default to the first line if no added lines are found
    }

    function createTable(violation, file, fileName, repo, branch, commentType) {
        const rulePath = violation.url ? violation.url : '';
        const filePath = `https://github.com/${repo}/blob/${branch}/${fileName}`;
        const fileHtml = commentType === 'pr' ? `<td>File</td><td><a href=${filePath} rel="nofollow">${fileName}</a></td>` : '<p></p>';
        return `<table role="table">
            <thead>
            <tr>
                <th>Attribute</th>
                <th>Value</th>
            </tr>
            </thead>
            <tbody>
            <tr>
                <td>Engine</td>
                <td>${file.engine}</td>
            </tr>
            <tr>
                <td>Category</td>
                <td>${violation.category}</td>
            </tr>
            <tr>
                <td>Rule</td>
                <td>${violation.ruleName}</td>
            </tr>
            <tr>
                <td>Line</td>
                <td>${violation.line}</td>
            </tr>
            <tr>
                <td>Severity</td>
                <td>${violation.severity}</td>
            </tr>
            <tr>
                <td>Message</td>
                <td><a href=${rulePath} rel="nofollow">${violation.message}</a></td>
            </tr>
            <tr>
                ${fileHtml}
            </tr>
            </tbody>
        </table>`
    }
}