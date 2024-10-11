/**
 * @author : Darshan S Almiya
 * @description : Controller class of hmCaseIdSearch related Components
 */
public with sharing class HMFlexiSearchController {
    @TestVisible
    private static HMFlexiSearchService flexiService = new HMFlexiSearchService();
    /**
     * @description : This method will provide all enabled custom permissions, related to Flexi Search.
     * @return : return List SearchType class which contains the search type information
     */

    @AuraEnabled(cacheable=true)
    public static List<HMFlexiSearchService.SearchType> getSearchTypes() {
        try {
            return flexiService.getSearchTypes();
        } catch (Exception ex) {
            Logger.error(ex.getMessage());
            Logger.saveLog();
        }
        return null;
    }

    /**
     * @description : Get the ResidentialLoanApplication based on the Name.
     * @param caseId : Name of ResidentialLoanApplication which is comes as caseId
     * @return List of ResidentialLoanApplication record based on Name
     */
    @AuraEnabled
    public static List<ResidentialLoanApplication> getResidentialLoanApplicationCaseId(
        final String caseId
    ) {
        try {
            return flexiService.getRLABasedOnCaseId(caseId);
        } catch (Exception ex) {
            Logger.error(ex.getMessage());
            Logger.saveLog();
        }
        return null;
    }

    /**
     * @description : Get the ResidentialLoanApplication based on the Mortgage Account Number
     * @param mortgageAccNumber : Pass the Mortgage Account Number
     * @return List of ResidentialLoanApplication record based on Mortgaage Account Number
     */

    @AuraEnabled
    public static List<ResidentialLoanApplication> getResidentialLoanApplicationAccountNo(
        final String mortgageAccNumber
    ) {
        try {
            return flexiService.getRLABasedOnMortgageAccNumber(
                mortgageAccNumber
            );
        } catch (Exception ex) {
            Logger.error(ex.getMessage());
            Logger.saveLog();
        }

        return null;
    }
}
