import { LightningElement, track, wire } from 'lwc';
import getSearchTypes from '@salesforce/apex/HMFlexiSearchController.getSearchTypes';
import NO_SEARCH_COMP_ACCESS_MSG from '@salesforce/label/c.HMNoSearchCompAccessMsg';
import SEARCH_PAGE_NAME from '@salesforce/label/c.HMSearchPageName';

export default class HmFlexiSearch extends LightningElement {
    genericMessage =  'There is an issue please contact to the Administrator';
    @track options = [];
    @track searchType = {
                            isApplicationSearch : false,
                            isCustomerSearch : false,
                            isCaseId : false,
                            isMortgageAccountNumberSearch : false
                        };
    permissionSetWrapper;
    strErrorDisplay;
    strSearchName = SEARCH_PAGE_NAME;

    /**
     * @description : This wire decorator which will get search type values.
     * @author : Darshan S Almiya
     * @param {*} none \
     */
    @wire(getSearchTypes) 
    searchTypes({error, data}){
      try{
        if(data){
          const objResponse = data;
          if(objResponse.length > 0){
            this.permissionSetWrapper = objResponse;
            this.permissionSetWrapper.map(item => {
              if(item.strSearchName in this.searchType){
                if(item.isSearch){
                  this.options.push({label: item.strRadioLabel, value: item.strRadioValue});
                }
              }
            })
          }else{
            this.strErrorDisplay = NO_SEARCH_COMP_ACCESS_MSG;
          }
        }
        else if(error){
          this.nebulaLogger(error.message);
          this.strErrorDisplay = this.genericMessage;
          
        }
      }catch(e){
        this.nebulaLogger(e.message);
        this.strErrorDisplay = this.genericMessage;
      }
    }

    /**
     * @description : onchange method of radio button field with help of update the Searchtype object variable values
     * @param {*} event : event coming from HTML page
     */
    handleChange(event){
        this.searchType = {};
        const selectedOption = event.detail.value;
        this.permissionSetWrapper.map(item => {
        if(item.strRadioValue == selectedOption){
            this.searchType[item.strSearchName] = true;
          }
        })
    }

    /**
     * @description : this.this.nebulaLoggerHandle to log the Error on Nebula Logger
     */

    nebulaLogger(error){
      const logger = this.template.querySelector("c-logger");
      logger.error(error);
      logger.saveLog()
  }
}
