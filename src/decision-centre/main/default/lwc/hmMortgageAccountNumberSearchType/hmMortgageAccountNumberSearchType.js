import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getResidentialLoanApplication from '@salesforce/apex/HMFlexiSearchController.getResidentialLoanApplicationAccountNo';

export default class HmMortgageAccountNumberSearch extends NavigationMixin(LightningElement) {
    strAccountNumberLabel = 'Mortgage Account Number';
    strvalidationHelptext = 'Must enter a number (up to a maximum of a 9 digit number)';
    validationMessage = 'Please enter a number up to 9 digits. The number should not start with a 0';
    regex = '^[1-9][0-9]*$';
    notFoundMessage = 'No results found';
    genericMessage = 'There is an issue please contact to the Administrator';
    mortgageAccNumber;
    isErrorDisplay;
    isSearchDisabled = true;

    /**
     * @description : This method will call from HTML to find the record, which is calling to the getResidentialLoanApplication method in Apex 
     */
    handleSearch(){
        getResidentialLoanApplication({mortgageAccNumber : this.mortgageAccNumber})
            .then(result => {
                try{
                    let lstRecords = result;
                    if(lstRecords && lstRecords[0]){
                        this.navigateToRecord(lstRecords[0].Id)
                    }else{
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
        this.mortgageAccNumber = event.target.value;
        var regexConst = new RegExp(this.regex);
        let isRegexResult = this.mortgageAccNumber.match(regexConst);
        if(isRegexResult){
            this.isSearchDisabled = false;
            this.isErrorDisplay = false;
        }else{
            this.isSearchDisabled = true;
            this.isErrorDisplay = true;
            this.strErrorDisplay = this.validationMessage;
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

    nebulaLogger(error){
        const logger = this.template.querySelector("c-logger");
        logger.error(error);
        logger.saveLog()
    }
}
