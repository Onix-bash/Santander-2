const xml2js = require('xml2js');
const fs = require('fs');
const {execSync} = require('child_process');

const GITHUB_HEAD_REF = process.env.GITHUB_HEAD_REF;
const GITHUB_BASE_REF = process.env.GITHUB_BASE_REF;
const GITHUB_BASE_BRANCH = GITHUB_HEAD_REF ? `origin/${GITHUB_BASE_REF}` : 'HEAD^';
const GITHUB_CURRENT_BRANCH = GITHUB_BASE_REF ? `origin/${GITHUB_HEAD_REF}` : '';
console.log('GITHUB_CURRENT_BRANCH', GITHUB_CURRENT_BRANCH, 'GITHUB_BASE_BRANCH',GITHUB_BASE_BRANCH);
const EXPRESSION_SET_FOLDER = 'src/decision-centre/main/default/expressionSetDefinition';
const XML_NAME = 'sourcePackage.xml'; 
const EXCLUDE_TYPE = 'ExpressionSetDefinition';

function start() {
    try {
        // Get Git Diff to track changes
        const changedExpressionSets = getDiff();
        console.log('diff', changedExpressionSets);
        // Set Source Manifest XML
        setManifest(changedExpressionSets);      
    } catch (error) {
        console.error('Error: ', error.message);
        process.exit(1);
    }
}

function getDiff() {
    execSync('git fetch origin');
    return execSync(`git diff --name-only ${GITHUB_BASE_BRANCH}...${GITHUB_CURRENT_BRANCH}`)
            .toString()
            .split('\n')
            .filter(file => file && file.startsWith(EXPRESSION_SET_FOLDER))
            .map((filename => filename.split('/').slice(-1).join()));
}

function setManifest(changedExpressionSets) {
    fs.readFile(XML_NAME, 'utf8', (err, data) => {
        if (err) {
            console.error(`Error reading file: ${err}`);
            throw new Error(`Error reading file: ${err}`);
        }

        // Parse XML to JSON
        xml2js.parseString(data, (err, result) => {
            if (err) {
                console.error(`Error parsing XML: ${err}`);
                throw new Error(`Error parsing XML: ${err}`)
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
                const xmlSource = builder.buildObject(result);

                // Write XML
                writeManifest(XML_NAME, xmlSource);                 
            }
        });
    })
}

function writeManifest(xmlName, xmlSource) {
    fs.writeFile(xmlName, xmlSource, 'utf8', err => {
        if (err) {
            console.error(`Error writing file: ${err}`);
            throw new Error(`Error writing file: ${err}`)
        }
    });
}

start();
