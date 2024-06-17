const fs = require('fs');

module.exports = async ({github, context}) => {
    const prNumber = context.payload.pull_request.number;
    const repoOwner = context.repo.owner;
    const repoName = context.repo.repo;

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

                    const message = createTable(violation, file, fileName);

                    // Determine the position in the diff
                    const position = getLineNumberFromDiff(currentFile.patch);
                    if (position !== null) {
                        try {
                            await github.rest.pulls.createReviewComment({
                                owner: repoOwner,
                                repo: repoName,
                                pull_number: prNumber,
                                body: message,
                                commit_id: context.payload.pull_request.head.sha,
                                path: fileName,
                                position: position,
                                side: 'RIGHT'
                            });
                        } catch (error) {
                            console.log(`Error: ${error.message}`);
                        }
                    } else {
                        try {
                            await github.rest.pulls.createReviewComment({
                                owner: repoOwner,
                                repo: repoName,
                                pull_number: prNumber,
                                body: message,
                                commit_id: context.payload.pull_request.head.sha,
                                path: fileName,
                                side: 'RIGHT',
                                subject_type: 'file'
                            });
                        } catch (error) {
                            console.log(`Error: ${error.message}`);
                        }
                    }
                }
            } else {
                let reviewComment = '';
                for (const violation of violations) {

                   reviewComment += '\n'+ createTable(violation, file);
                   console.log('reviewComment = ', reviewComment)
                }
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

            console.log('reviewComment', reviewComment);


        }
    } catch (error) {
        console.log(`Error: ${error.message}`);
    }

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

    function createTable(violation, file, fileName) {
        const rulePath = violation.url ? violation.url : '';
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
                <td>File</td>
                <td>${fileName}></td>
            </tr>
            </tbody>
        </table>`
    }
}