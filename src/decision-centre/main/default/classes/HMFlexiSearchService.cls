/**
 * @author : Darshan Singh Almiya
 * @description : This is Service class for Flexi Search Controller Class
 */
public with sharing virtual class HMFlexiSearchService {
    /**
     * @description : Get the ResidentialLoanApplication records based on caseId(Name)
     * @param caseId : Provide the CaseId
     * @return List of ResidentialLoanApplication
     */
     public virtual List<ResidentialLoanApplication> getRLABasedOnCaseId(final String caseId){
        return [SELECT Id FROM ResidentialLoanApplication WHERE Name = :caseId WITH SECURITY_ENFORCED];
    }

    /**
     * @description : Get the ResidentialLoanApplication records based on Mortgage Account Number
     * @param mortgageAccNumber : Provide the Mortgage Account Number
     * @return List of ResidentialLoanApplication
     */
     public virtual List<ResidentialLoanApplication> getRLABasedOnMortgageAccNumber(final String mortgageAccNumber){
        return [SELECT Id FROM ResidentialLoanApplication WHERE HMMortgageAccountNumber__c = :mortgageAccNumber WITH SECURITY_ENFORCED];
    }
 
    /**
     * @description : Get the HMFlexiSearchAccessSetting__mdt metadata records and pass to the getAllowedSearchTypes method to filter the records.
     * @return : return List<SearchType> class which contains Custom metadata details.
     */
    public virtual List<SearchType> getSearchTypes(){
        HMFlexiSearchService hmFlexiServiceObj= new HMFlexiSearchService();
        List<SearchType> lstCustomPermission = new List<SearchType>();
        Map<String, HMFlexiSearchAccessSetting__mdt> mapLightningSearch = new Map<String, HMFlexiSearchAccessSetting__mdt>();
        for(HMFlexiSearchAccessSetting__mdt lightningSearch : HMFlexiSearchAccessSetting__mdt.getAll().values()){
            mapLightningSearch.put(lightningSearch.HMCustomPermissionName__c, lightningSearch);
        }
        return hmFlexiServiceObj.getAllowedSearchTypes(mapLightningSearch);
    }
    /**
     * @description : Filter the Custom metadata based on custom permissions
     * @param mapLightningSearch : Map of HMFlexiSearchAccessSetting__mdt metadata
     * @return : List of SearchType Wrapper Class
     */
    @TestVisible
    private virtual List<SearchType> getAllowedSearchTypes(final Map<String, HMFlexiSearchAccessSetting__mdt> mapLightningSearch){
        List<SearchType> lstCustomPermission = new List<SearchType>();
        for(String strCustomPermission : mapLightningSearch.keySet()){
            SearchType objCustomPermission = new SearchType();
            Boolean isPermissionAssign = FeatureManagement.checkPermission(strCustomPermission);
            if(isPermissionAssign){
                HMFlexiSearchAccessSetting__mdt lightningSearchMetaData = mapLightningSearch.get(strCustomPermission);
                objCustomPermission.isSearch = isPermissionAssign;
                objCustomPermission.strSearchName = lightningSearchMetaData.HMLightningHTMLSearchName__c;
                objCustomPermission.strRadioLabel = lightningSearchMetaData.HMRadioButtonLabel__c;
                objCustomPermission.strRadioValue = lightningSearchMetaData.HMRadioButtonLabel__c;
                lstCustomPermission.add(objCustomPermission);
            }
        }
        return lstCustomPermission;
    }

    /**
     * @description : This is wrapper class which contain the data based on Custom Metadata and Custom Permisssion
     */
    public class SearchType{
        @AuraEnabled
        public Boolean isSearch;
        @AuraEnabled
        public String strSearchName;
        @AuraEnabled
        public String strRadioLabel;
        @AuraEnabled
        public String strRadioValue;
        public SearchType(){
            isSearch = false;
            strSearchName = null;
        }
    }
}