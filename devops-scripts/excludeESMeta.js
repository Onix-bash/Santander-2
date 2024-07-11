const xml2js = require('xml2js');
const fs = require('fs');
const {execSync} = require('child_process');

const GITHUB_BASE_REF = process.env.GITHUB_HEAD_REF;
const GITHUB_HEAD_REF = process.env.GITHUB_BASE_REF;
console.log(GITHUB_BASE_REF);
console.log(GITHUB_HEAD_REF);

// Get environment variables from GitHub Actions
const sourceToCheckChanges = `origin/${GITHUB_BASE_REF}`;
const currentBranch = `origin/${GITHUB_HEAD_REF}`;

const PACKAGE_XML = 'sourcePackage.xml'; // Path to deploy
const EXCLUDE_TYPE = 'ExpressionSetDefinition'; // Metadata types to exclude

function getDiff() {
    try {
        execSync('git fetch origin');
        const diff = execSync(`git diff --name-only ${sourceToCheckChanges}...${currentBranch}`);
        console.log(`git diff --name-only ${sourceToCheckChanges}...${currentBranch}`)
        console.log('diff', diff.toString());
        const gitDiff = execSync(`git diff --name-only ${sourceToCheckChanges}...${currentBranch}`)
            .toString()
            .split('\n')
            .filter(file => file && file.startsWith('src/decision-centre/main/default/expressionSetDefinition'))
            .map((filename => filename.split('/').slice(-1).join()));

        // Delete unchanged ES from sourcePackage.xml
        console.log('gitDiff', gitDiff)
        deleteESMeta(gitDiff);
    } catch (error) {
        console.error('Error executing git diff:', error.message);
    }
}

function deleteESMeta(changedES) {
    fs.readFile(PACKAGE_XML, 'utf8', (err, data) => {
        if (err) {
            console.error(`Error reading file: ${err}`);
            return;
        }

        // Parse XML to JSON
        xml2js.parseString(data, (err, result) => {
            if (err) {
                console.error(`Error parsing XML: ${err}`);
                return;
            }

            if (result.Package.types) {
                // Filter ES Members
                if (!changedES.length) {
                    result.Package.types = result.Package.types.filter(type => {
                        return EXCLUDE_TYPE !== type.name[0];
                    }); // delete all members
                } else {

                    const changedFilesNames = changedES.map(file => file.split('.')[0]);
                    console.log(changedFilesNames)
                    result.Package.types.filter(type => {

                            if (type.name[0] === EXCLUDE_TYPE) {
                                type.members = type.members.filter(member => changedFilesNames.includes(member))
                            }
                            return type;
                        }
                    )
                }

                // Build XML from JSON
                const builder = new xml2js.Builder();
                const xml = builder.buildObject(result);

                // Write Back XML File
                writeXML(PACKAGE_XML, xml)
            }
        });
    })
}

function writeXML(XMLPath, xml) {
    fs.writeFile(XMLPath, xml, 'utf8', err => {
        if (err) {
            console.error(`Error writing file: ${err}`);
        }
    });
}
getDiff();