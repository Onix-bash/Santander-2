const xml2js = require('xml2js');
const core = require('@actions/core');
const fs = require('fs');
const exec = require('@actions/exec');

const GITHUB_HEAD_REF = process.env.GITHUB_HEAD_REF;
const GITHUB_BASE_REF = process.env.GITHUB_BASE_REF;
const GITHUB_BASE_BRANCH = GITHUB_BASE_REF ? `origin/${GITHUB_BASE_REF}` : 'HEAD^';
const GITHUB_CURRENT_BRANCH = GITHUB_HEAD_REF ? `origin/${GITHUB_HEAD_REF}` : '';

const EXPRESSION_SET_FOLDER = 'src/decision-centre/main/default/expressionSetDefinition';
const PACKAGE_XML_FILENAME = 'sourcePackage.xml';
const EXCLUDE_TYPE = 'ExpressionSetDefinition';

async function run() {
    try {
        // Get Git Diff to track changes
        const changedExpressionSets = await findChangedExpressionSets();
        // Set Source Manifest XML
        removeUnchangedExpressionSetsFromManifest(changedExpressionSets);      
    } catch (error) {
        core.setFailed(`${error.message}`);
    }
}

async function findChangedExpressionSets() {
    await exec.exec('git fetch origin');
    const { stdout, stderr, exitCode} = await exec.getExecOutput(`git diff --name-only ${GITHUB_BASE_BRANCH}...${GITHUB_CURRENT_BRANCH}`)
    
    if (exitCode != 0) {
        throw new Error(`Git diff command failed: ${stderr}`)
    }
    return stdout.split('\n')
        .filter(file => file && file.startsWith(EXPRESSION_SET_FOLDER))
        .map((filename => filename.split('/').slice(-1).join()));
}

function removeUnchangedExpressionSetsFromManifest(changedExpressionSets) {
    fs.readFile(PACKAGE_XML_FILENAME, 'utf8', (err, data) => {
        if (err) {
            core.setFailed(`Error reading file: ${err}`);
        }

        // Parse XML to JSON
        xml2js.parseString(data, (err, result) => {
            if (err) {
                core.setFailed(`Error parsing XML: ${err}`);
            }

            if (result.Package.types) {
                // Filter ExpressionSets Rows/Members
                if (!changedExpressionSets.length) {
                    // Exclude all Rows/Members
                    result.Package.types = result.Package.types.filter(type => {
                        return EXCLUDE_TYPE !== type.name[0];
                    }); 
                } else {
                    // Set Rows/Members
                    const changedFilesNames = changedExpressionSets.map(file => file.split('.')[0])
                    result.Package.types.filter(type => {
                        if (type.name[0] === EXCLUDE_TYPE) {
                            type.members = type.members.filter(member => changedFilesNames.includes(member))
                        }
                        return type;
                    })
                }

                // Build XML from JSON
                const builder = new xml2js.Builder();
                const packageXMLContent = builder.buildObject(result);

                // Write XML
                fs.writeFile(PACKAGE_XML_FILENAME, packageXMLContent, 'utf8', err => {
                  if (err) {
                      core.setFailed(`Error writing file: ${err}`);
                  }
                });
            }
        });
    })
}


run();