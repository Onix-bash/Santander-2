/**
* @description : This is Test class of HMFlexiSearchController
 */
@isTest
public without sharing class HMFlexiSearchControllerTest {
    public virtual class CustomException extends Exception {}

    private class FlexiServiceMock extends HMFlexiSearchService {
      public override List<HMFlexiSearchService.SearchType> getSearchTypes() {    
        List<HMFlexiSearchService.SearchType> lstSearchType = new List<HMFlexiSearchService.SearchType>();
        HMFlexiSearchService.SearchType objSearchType = new HMFlexiSearchService.SearchType();
        objSearchType.isSearch = true;
        objSearchType.strRadioLabel = 'Application';
        objSearchType.strRadioValue = 'Application';
        objSearchType.strSearchName = 'isApplicationSearch';
        lstSearchType.add(objSearchType);
        return lstSearchType;
      }

      public override List<ResidentialLoanApplication> getRLABasedOnCaseId(final String caseId){
        List<ResidentialLoanApplication> lstResidentialLoanApplication = new List<ResidentialLoanApplication>();
        ResidentialLoanApplication objResidentialLoanApplication = new ResidentialLoanApplication(Id='0cdKO0000004C93YAE', Name='AM123456789');
        lstResidentialLoanApplication.add(objResidentialLoanApplication);
        return lstResidentialLoanApplication;
      }

      public override List<ResidentialLoanApplication> getRLABasedOnMortgageAccNumber(final String mortgageAccNumber){
        List<ResidentialLoanApplication> lstResidentialLoanApplication = new List<ResidentialLoanApplication>();
        ResidentialLoanApplication objResidentialLoanApplication = new ResidentialLoanApplication(Id='0cdKO0000005C93YAE', HMMortgageAccountNumber__c='123456789');
        lstResidentialLoanApplication.add(objResidentialLoanApplication);
        return lstResidentialLoanApplication;
      }

      public override List<SearchType> getAllowedSearchTypes(final Map<String, HMFlexiSearchAccessSetting__mdt> mapLightningSearch) {    
        List<HMFlexiSearchService.SearchType> lstSearchType = new List<HMFlexiSearchService.SearchType>();
        HMFlexiSearchService.SearchType objSearchType = new HMFlexiSearchService.SearchType();
        objSearchType.isSearch = true;
        objSearchType.strRadioLabel = 'Application';
        objSearchType.strRadioValue = 'Application';
        objSearchType.strSearchName = 'isApplicationSearch';
        lstSearchType.add(objSearchType);
        return lstSearchType;
      }
    }

    private class FlexiServiceExceptionMock extends HMFlexiSearchService {
      public override List<SearchType> getSearchTypes() {    
        throw new CustomException('This is bad search Details');
      }
      public override List<SearchType> getAllowedSearchTypes(final Map<String, HMFlexiSearchAccessSetting__mdt> mapLightningSearch) {    
        throw new CustomException('This is bad Allowed Search');
      }
      public override List<ResidentialLoanApplication> getRLABasedOnCaseId(final String caseId){
        throw new CustomException('This is bad case Id');
      }
      public override List<ResidentialLoanApplication> getRLABasedOnMortgageAccNumber(final String mortgageAccNumber){
        throw new CustomException('This is bad Account Number');
      }
    }

    @isTest
    public static void getSearchDetailsTest(){
      List<HMFlexiSearchService.SearchType> result = new List<HMFlexiSearchService.SearchType>();
        Test.startTest();
        System.runAs(new User(Id=UserInfo.getUserId())) {
          HMFlexiSearchController.flexiService = new FlexiServiceMock();
          result = HMFlexiSearchController.getSearchTypes();
        }
      Test.stopTest();
      Assert.isNotNull(result, 'result should not be null');
    }
    
    @isTest
    public static void getResidentialLoanApplicationTest(){
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(new User(Id=UserInfo.getUserId())) {
        HMFlexiSearchController.flexiService = new FlexiServiceMock();
        result = HMFlexiSearchController.getResidentialLoanApplicationCaseId('AM000000001');
      }
      Test.stopTest();
      Assert.areEqual(1, result.size(), 'result should returned one record');
    }

    @isTest
    public static void getResidentialLoanApplicationAccountNumberTest(){
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
        Test.startTest();
        System.runAs(new User(Id=UserInfo.getUserId())) {
          HMFlexiSearchController.flexiService = new FlexiServiceMock();
          result = HMFlexiSearchController.getResidentialLoanApplicationAccountNo('123456789');
        }
        Test.stopTest();
        Assert.areEqual(1, result.size(), 'result should returned one record');
    }

    @isTest
    public static void getResidentialLoanApplicationExceptionTest(){
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(new User(Id=UserInfo.getUserId())) {
        HMFlexiSearchController.flexiService = new FlexiServiceExceptionMock();
        result = HMFlexiSearchController.getResidentialLoanApplicationCaseId(null);
      }
      Test.stopTest();
      Assert.isNull(result, 'result should be null');
    }
	@isTest
    public static void getResidentialLoanApplicationAcNoExceptionTest(){
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(new User(Id=UserInfo.getUserId())) {
        HMFlexiSearchController.flexiService = new FlexiServiceExceptionMock();
        result = HMFlexiSearchController.getResidentialLoanApplicationAccountNo(null);
      }
      Test.stopTest();
      Assert.isNull(result, 'result should be null');
  }

  @isTest
    public static void getSearchDetailsExceptionTest(){
      List<HMFlexiSearchService.SearchType> result = new List<HMFlexiSearchService.SearchType>();
        Test.startTest();
        System.runAs(new User(Id=UserInfo.getUserId())) {
          HMFlexiSearchController.flexiService = new FlexiServiceExceptionMock();
          result = HMFlexiSearchController.getSearchTypes();
        }
      Test.stopTest();
      Assert.isNull(result, 'result should be null');
    }
}