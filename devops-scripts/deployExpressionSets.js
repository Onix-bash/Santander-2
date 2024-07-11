const xml2js = require('xml2js');
const fs = require('fs');
const path = require('path');
const {execSync} = require('child_process');
console.log(process.env.GITHUB_HEAD_REF)

// Get environment variables from GitHub Actions
const sourceToCheckChanges = `origin/${GITHUB_BASE_REF}`;
const currentBranch = `origin/${GITHUB_HEAD_REF}`;

const PACKAGE_XML = 'sourcePackage.xml'; // Path to deploy
const EXCLUDE_TYPE = 'ExpressionSetDefinition'; // Metadata types to exclude
const ESPath = 'src/decision-centre/main/default/expressionSetDefinition'

function getDiff() {
    try {
        execSync('git fetch origin');
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

const disableActiveVersion = (apiName) => {

    const queryToGetActiveES = (apiName) => (
        `"SELECT Id, ApiName, VersionNumber FROM ExpressionSetVersion ` +
        `WHERE IsActive=TRUE AND ApiName='${apiName}' LIMIT 1"`
    );

    try {
        const QUERY = queryToGetActiveES(apiName)
        const res = execSync(`sf data query --query ${QUERY} --json`, {encoding: 'utf8'});
        const records = JSON.parse(res).result.records;

        if (records.length) {
            const currentVersionId = records[0].Id;
            try {
                execSync(`sf data update record --sobject ExpressionSetVersion --record-id ${currentVersionId} --values "IsActive=false"`, {
                    silent: false,
                    encoding: 'utf8'
                });
            } catch (err) {
                console.error(`Error disabling active version: ${err}`);
            }

        } else console.log(`No active version for ${apiName}`)
    } catch (err) {
        console.error(`Error getting current ES: ${err}`);
    }
};

const getVersionByFileName = (file) => {
    try {
        const filePath = path.join(ESPath, file);
        const xmlData = fs.readFileSync(filePath, 'utf8');

        // Parse XML to JSON
        let parsedJson;
        xml2js.parseString(xmlData, (err, result) => {
            if (err) {
                console.error(`Error parsing XML file ${file}: ${err}`);
                return null;
            }
            parsedJson = result.ExpressionSetDefinition; // Adjust according to your XML structure
        });

        if (parsedJson && parsedJson.versions) {
            // console.log(parsedJson.versions)
            return parsedJson.versions.map(version => ({
                apiName: version.fullName[0],
                versionNumber: version.versionNumber[0],
                fileName: version.expressionSetDefinition[0]
            }))[0];
        }
        return null;
    } catch (err) {
        console.error('Error processing XML files:', err);
        return [];
    }
};

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
                    changedES.forEach(file => {
                        const {apiName, versionNumber, fileName} = getVersionByFileName(file);
                        console.log(apiName, versionNumber, fileName)
                        if (versionNumber > 1) {
                            disableActiveVersion(apiName)
                        }
                    });

                    const changedFilesNames = changedES.map(file => file.split('.')[0])
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