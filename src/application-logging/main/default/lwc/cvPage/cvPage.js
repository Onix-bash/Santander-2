/**
 * Represents a Lightning Web Component for displaying and managing an Employee CV Page.
 * This component includes features such as editing skills, title, and experience details, as well as generating CVs.
 *
 * @author      Vladislav V.
 * @date        17.01.2024
 * @revision 1    17.01.2024 - [Vladislav V.] - Initial version
 */
import {LightningElement, track, api} from 'lwc';
import PROFILE from '@salesforce/resourceUrl/Profile_Photo';
import getEmployeeDetails from '@salesforce/apex/EmployeeHandler.getEmployeeDetails';
import updateEmployeeDetails from '@salesforce/apex/EmployeeHandler.updateEmployeeDetails';
import createNewEmployeeRole from '@salesforce/apex/EmployeeHandler.createNewEmployeeRole';
import updateEmployeeRoles from '@salesforce/apex/EmployeeHandler.updateEmployeeRoles';
import deleteEmployeeRole from '@salesforce/apex/EmployeeHandler.deleteEmployeeRole';
import {NavigationMixin} from 'lightning/navigation';
import {LABELS} from "c/labels";
import {createSessionData, fetchStatus, redirectToPage} from "c/service";
export default class CvPage extends NavigationMixin (LightningElement) {
    @track employeeDetails = {};
    @track showEmployeeModal = false;
    @track storeSession = false;
    @api recordId;
    avatar;
    isEditSkills = false;
    isEditTitle = false;
    isEditExperience = false;
    isLoading = true;
    salesforceCRM;
    generalSoftwareDevelopment;
    other;
    otherProgrammingLanguages;
    languages;
    roleName;
    title;
    startDate;
    endDate;
    description;
    currentUserName;
    isExperience = false;
    noExperience = false;
    sessionDetails = null;
    defaultPhoto = PROFILE;

    labels = LABELS;

    TESTVAR = true;

    /**
     * Initiates data loading.
     */
    async connectedCallback() {
        this.sessionDetails = createSessionData(this.labels);
        this.currentUserName = this.sessionDetails.name;
        this.userRecordType = await fetchStatus(this.sessionDetails.username, JSON.stringify(this.sessionDetails));

        this.avatar = JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).avatar ?
            JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).avatar : this.defaultPhoto;

        this.getEmployeeDetails();

        for (let i = 0; i < 5; i++)
            console.log('qwe');
    }

    /**
     * Checks if the current user is an owner or an assistant manager.
     * @returns {boolean} True if the user is an owner or an assistant manager, false otherwise.
     */
    get isOwnerOrAssistingManager() {
        return this.userRecordType === 'Sales Manager' || this.userRecordType === 'Brand Manager';
    }

    /**
     * Handles changes in input fields.
     * This method updates the corresponding class properties based on the user input.
     * @param {Event} event - The event containing the changed field.
     */
    fieldEdit(event) {
        const field = event.target;
        this[field.name] = field.value;
    }

    /**
     * Handles changes in role fields
     * @param {Event} event - The event containing the changed field.
     */
    roleEdit(event) {
        const field = event.target;
        const index = field.dataset.index;
        const fieldName = field.dataset.id;

        this.employeeDetails.roles[index][fieldName] = field.value;
    }

    /**
     * Retrieves employee details from the Apex controller.
     */
    getEmployeeDetails() {
        this.noExperience = false;
        const username = this.selectedEmployeeUsername || this.sessionDetails.username;
        const sessionData = JSON.stringify(this.sessionDetails);

        getEmployeeDetails({
            username: this.selectedEmployeeUsername || this.sessionDetails.username,
            sessionData: JSON.stringify(this.sessionDetails),
        })
            .then((employee) => {
                if (employee) {
                    this.employeeDetails = employee;
                    // this.employeeDetails.role =
                    //     this.avatar = employeeDetails.avatar != null ? employeeDetails.avatar : this.defaultPhoto;
                    this.mapRoles(this.employeeDetails.roles);
                    this.checkRoles();

                    this.isExperience = true;
                    this.setLoading();
                }
            })
            .catch((error) => {
                this.setLoading();
                if (error.body.message.includes(this.labels.INVALID_SESSION)) {
                    redirectToPage('profile', 'login');
                }
            });
    }

    /**
     * Maps the roles array to include an index property.
     * This method iterates over each role object in the provided roles array and adds an index property to each role.
     * The index property represents the position of the role in the array, starting from 1.
     *
     * @param {Object[]} roles - The array of role objects to be mapped.
     * @returns {Object[]} The mapped array of role objects with an additional index property.
     */
    mapRoles(roles) {
        return roles.map((role, index, array) => {
            role.roleId; //test
            role.roleName;//test
            role.startDate;//test
            role.endDate;//test
            role.description;
            role.index = index + 1;
        });
    }

    /**
     * Checks if the employee has any roles or experience.
     * This method examines the roles array of the employee details.
     * If the roles array is empty, it sets the 'noExperience' property to true, indicating that the employee has no experience.
     */
    checkRoles() {
        if (this.employeeDetails.roles.length === 0) {
            this.noExperience = true;
        }
    }

    /**
     * Sets the loading state.
     */
    setLoading() {
        this.isLoading = !this.isLoading;
    }

    /**
     * Sets the component into edit mode for skills.
     * This method sets the 'isEditSkills' property to true, indicating that the component is now in edit mode for skills.
     */
    editSkills() {
        this.isEditSkills = true;
    }

    /**
     * Sets the component into edit mode for the title.
     * This method sets the 'isEditTitle' property to true, indicating that the component is now in edit mode for the title.
     */
    editTitle() {
        this.isEditTitle = true;
    }

    /**
     * Sets the component into edit mode for experience details.
     * This method sets the 'isEditExperience' property to true, indicating that the component is now in edit mode for experience details.
     */
    editExperience() {
        this.isEditExperience = true;
    }

    /**
     * Adds a new experience entry for the current employee.
     * This method initiates the process of creating a new employee role using the 'createNewEmployeeRole' Apex method.
     * Upon successful creation, it reloads the employee data and sets the loading state.
     */
    addExperience() {
        let sessionData = createSessionData(this.labels);

        createNewEmployeeRole({
            username: JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).username,
            sessionData: JSON.stringify(sessionData),
        })
            .then((result) => {
                if (result) {
                }
                this.connectedCallback();
                this.setLoading();
            })
            .catch((error) => {
                console.error(error);
            });
    }

    /**
     * Handles the save action for updating employee details.
     * This method determines the type of update based on the event target dataset.
     * It constructs the details object accordingly and sends the update request to the server using 'updateEmployeeDetails'.
     * Upon successful update, it reloads the employee data, exits the edit mode for the corresponding section, and sets the loading state.
     *
     * @param {Event} event - The event containing the target dataset to determine the type of update.
     */
    handleSave(event) {
        const type = event.target.dataset.type;

        let sessionData = createSessionData(this.labels);
        let details;

        if (type === 'skills') {
            details = {
                salesforceCRM: this.salesforceCRM != null ? this.salesforceCRM : this.employeeDetails.salesforceCRM,
                generalSoftwareDevelopment: this.generalSoftwareDevelopment != null ? this.generalSoftwareDevelopment :
                    this.employeeDetails.generalSoftwareDevelopment,
                other: this.other != null ? this.other : this.employeeDetails.other,
                otherProgrammingLanguages: this.otherProgrammingLanguages != null ? this.otherProgrammingLanguages :
                    this.employeeDetails.otherProgrammingLanguages,
                languages: this.languages != null ? this.languages : this.employeeDetails.languages,
                username: JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).username
            };
        } else if (type === 'title') {
            details = {
                title: this.title != null ? this.title : this.employeeDetails.title,
                username: JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).username
            };
        }
        updateEmployeeDetails({
            cvData: JSON.stringify(details),
            sessionData: JSON.stringify(sessionData),
            updateType: type
        })
            .then((result) => {
                if (result) {
                }
                this.connectedCallback();
                this[`isEdit${type.charAt(0).toUpperCase() + type.slice(1)}`] = false;
                this.setLoading();
            })
            .catch((error) => {
                console.error(error);
            });
    }

    /**
     * Handles the cancellation action for editing skills, title, or experience details.
     * This method retrieves the section type from the event target dataset.
     * Depending on the section type, it exits the corresponding edit mode by setting the corresponding property to false.
     *
     * @param {Event} event - The event containing the target dataset to determine the section type.
     */
    handleCancel(event) {
        const sectionType = event.target.dataset.section;

        if (sectionType === 'skills') {
            this.isEditSkills = false;
        } else if (sectionType === 'title') {
            this.isEditTitle = false;
        } else if (sectionType === 'experience') {
            this.isEditExperience = false;
        }
    }

    /**
     * Handles the update action for employee roles.
     * This method constructs the updated role details based on the current employee roles.
     * It then sends the update request to the server using 'updateEmployeeRoles'.
     * Upon successful update, it exits the edit mode for experience details, reloads the employee data, and sets the loading state.
     *
     * @param {Event} event - The event containing the target dataset to determine the section type.
     */
    handleUpdateRoles(event) {
        let sessionData = createSessionData(this.labels);
        let updatedRoles = [];

        for (let i = 0; i < this.employeeDetails.roles.length; i++) {
            let role = this.employeeDetails.roles[i];

            let roleDetails = {
                roleId: role.roleId,
                roleName: role.roleName,
                startDate: role.startDate,
                endDate: role.endDate,
                description: role.description,
                username: JSON.parse(localStorage.getItem(this.labels.SESSION_DETAILS)).username,
            };

            updatedRoles.push(roleDetails);
        }

        if (updatedRoles.length > 0) {
            updateEmployeeRoles({
                rolesData: JSON.stringify(updatedRoles),
                sessionData: JSON.stringify(sessionData),
            })
                .then((result) => {
                    if (result) {
                    }
                    this.isEditExperience = false;
                    this.connectedCallback();
                    this.setLoading();
                })
                .catch((error) => {
                    console.error(error);
                });
        }
    }

    /**
     * Handles the deletion of a specific employee role.
     * This method retrieves the index of the role to be deleted from the event target dataset.
     * It then sends a deletion request to the server using 'deleteEmployeeRole'.
     * Upon successful deletion, it reloads the employee data and sets the loading state.
     *
     * @param {Event} event - The event containing the target dataset to determine the index of the role to be deleted.
     */
    handleDeleteRole(event) {
        let index = event.target.dataset.index;

        let sessionData = createSessionData(this.labels);

        deleteEmployeeRole({
            roleId: this.employeeDetails.roles[index].roleId,
            sessionData: JSON.stringify(sessionData),
        })
            .then((result) => {
                if (result) {
                }
                this.connectedCallback();
                this.setLoading();
            })
            .catch((error) => {
                console.error(error);
            });
    }

    /**
     * Handles the generation of a CV for the current employee.
     * This method constructs the Visualforce page URL for generating the CV based on the current user's username.
     * It then navigates to the generated CV page using the 'NavigationMixin' and a standard web page type.
     */
    handleGenerateCV() {
        const username = this.selectedEmployeeUsername || this.sessionDetails.username;
        const vfPageUrl = 'https://onixconsulting--portal--c.sandbox.vf.force.com/apex/CVGenerator?username=' +
            username;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: vfPageUrl
            }
        }).catch(error => {
            console.error('Error navigating to VF page:', error);
        });
    }

    /**
     * Handles the generation of an unnamed CV for the current employee.
     * This method constructs the Visualforce page URL for generating an unnamed CV based on the current user's username.
     * It then navigates to the generated CV page using the 'NavigationMixin' and a standard web page type.
     */
    handleGenerateUnnamedCV() {
        const username = this.selectedEmployeeUsername || this.sessionDetails.username;
        const isUnnamed = 'true';
        const vfPageUrl = `https://onixconsulting--portal--c.sandbox.vf.force.com/apex/CVGenerator?username=${username}&isUnnamed=${isUnnamed}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: vfPageUrl
            }
        }).catch(error => {
            console.error('Error navigating to VF page:', error);
        });
    }

    /**
     * Opens the employee selection modal.
     */
    openEmployeeModal() {
        this.showEmployeeModal = true;
    }

    /**
     * Closes the employee selection modal.
     */
    closeEmployeeModal() {
        this.showEmployeeModal = false;
    }

    /**
     * Handles employee selection from the modal, updating the component state with the selected employee's data.
     * @param {CustomEvent} event - Event containing the selected employee's details.
     */
    handleEmployeeSelection(event) {
        const {selectedEmployeeUsername, selectedEmployeeName, selectedEmployeeAvatar} = event.detail;

        this.currentUserName = selectedEmployeeName;
        this.avatar = selectedEmployeeAvatar ? selectedEmployeeAvatar : PROFILE;
        this.selectedEmployeeUsername = selectedEmployeeUsername;
        this.getEmployeeDetails();
    }
}


const fs = require('fs');
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

                const rulePath = violation.url ? violation.url : '';
                const message = `<table role="table"><thead><tr><th>Attribute</th><th>Value</th></tr></thead><tbody><tr><td>Engine</td><td>${file.engine}</td></tr>
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
                                                               <td><a href=${currentFile.filename}>${currentFile.filename}</a></td>
                                                               </tr>
                                                               </tbody>
                                                               </table>`;
                // Determine the position in the diff
                const patchLines = currentFile.patch.split('\n');
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
                    }
                    if (inHunk) {
                        if (line.startsWith('+') && !line.startsWith('+++')) {
                            diffLine++;
                            if (diffLine === violation.line) {
                                position = i + 1; // GitHub's position is 1-based
                                break;
                            }
                        } else if (!line.startsWith('-')) {
                            originalLine++;
                        }
                    }
                }

                if (position !== null) {
                    console.log('position', position);
                    console.log('violation.line', violation.line);
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
                    console.log(`Skipping comment for violation at line ${violation.line} as it's not found in the diff.`);
                }
            }
        }
    }
} catch (error) {
    console.log(`Error: ${error.message}`);

}
