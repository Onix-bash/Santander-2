import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getResidentialLoanApplication from '@salesforce/apex/HMFlexiSearchController.getResidentialLoanApplicationCaseId';

/**
 * @description : This is HmCaseIdSearch Component belong to the caseid search.
 * @author : Darshan S Almiya
*/
export default class HmCaseIdSearch extends NavigationMixin(LightningElement) {
    strCaseIdLabel = 'Case ID';
    strvalidationHelptext = 'Must be entered as “AM” followed by a 9 digit number';
    validationMessage = 'Please enter the relevant prefix followed by a 9 digit number';
    caseIdRegex = '^AM\\d\\d\\d\\d\\d\\d\\d\\d\\d$';
    notFoundMessage = 'No results found';
    genericMessage = 'There is an issue please contact to the Administrator';
    caseId = 'AM';
    isSearchDisabled = true;
    isErrorDisplay = false;
    strErrorDisplay;

    /**
     * @description : This method will call from HTML to find the record, which is calling to the getResidentialLoanApplication method in Apex 
     */
    handleSearch(){
        getResidentialLoanApplication({caseId : this.caseId})
            .then(result => {
                try{
                    this.isErrorDisplay = false;
                    let lstRecords = result;
                    if(lstRecords && lstRecords[0]){
                        this.navigateToRecord(lstRecords[0].Id)
                    }else if(lstRecords && lstRecords.length == 0){
                        this.isErrorDisplay = true;
                        this.strErrorDisplay = this.notFoundMessage;
                    }
                }catch(e){
                    this.isErrorDisplay = true;
                    this.strErrorDisplay = this.genericMessage;
                    this.nebulaLogger(e.message);
                    
                }
            })
            .catch(e => {
                this.isErrorDisplay = true;
                this.strErrorDisplay = this.genericMessage;
                this.nebulaLogger(e.message);
            });
    }

    /**
     * @description : In this method we get the input values from HTML and match with the regex based on that we display an error message
     * @param {*} event  : event we get from HTML
     */

    handleInput(event){
        try{
            this.isErrorDisplay = false;
            this.caseId = event.target.value;
            var regexConst = new RegExp(this.caseIdRegex);
            let isRegexResult = this.caseId.match(regexConst);
            if(isRegexResult){
                this.isSearchDisabled = false;
                this.isErrorDisplay = false;
            }else{
                this.isSearchDisabled = true;
                this.isErrorDisplay = true;
                this.strErrorDisplay = this.validationMessage;
            }
            
        }catch(e){
            this.isErrorDisplay = true;
            this.strErrorDisplay = this.genericMessage;
            this.nebulaLogger(e.message);
        }
        
    }

    /**
     * @description : Navigate into the standard rcord page
     * @param {*} strRecordId : record Id to navigate into the record
     */
    navigateToRecord(strRecordId) {
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: strRecordId,
                actionName: 'view'
            }
        });
    }

    /**
     * @description : this.nebulaLoggerHandle to log the Error on Nebula Logger
     */

    nebulaLogger(error){
        const logger = this.template.querySelector("c-logger");
        logger.error(error);
        logger.saveLog()
    }

}