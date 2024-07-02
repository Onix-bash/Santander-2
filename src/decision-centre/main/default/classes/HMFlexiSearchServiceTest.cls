@isTest
public without sharing class HMFlexiSearchServiceTest {
    public static HMFlexiSearchService hmFlexiSearchServiceObj = new HMFlexiSearchService();
    @testSetup
    static void setup() {
      ResidentialLoanApplication objRLA = new ResidentialLoanApplication();
      objRLA.Name = 'AM000000001';
      objRLA.HMMortgageAccountNumber__c = '123456789';
      HMTestDataFactory.createResidentailLoanApplication(objRLA, true);
      HMTestDataFactory.createResidentailLoanApplication('AM000000002', true);
      HMTestDataFactory.createUser('minaccessuser_underwrittertest@testorg.com', 'Minimum Access - Salesforce');
      HMTestDataFactory.createUser('minaccessuser_underwrittertestMinimum@testorg.com', 'Minimum Access - Salesforce');
      // We are asssigning the Permission set in the respective test method to overome mixed DML Error
  }
    @IsTest
    static void getRLABasedOnCaseIdTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnCaseId('AM000000001');
      }
      Test.stopTest();
      Assert.areEqual(1, result.size(), 'Must be returned one record');
    }

    @IsTest
    static void getRLABasedOnMortgageAccNumberTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnMortgageAccNumber('123456789');
      }
      Test.stopTest();
      Assert.areEqual(1, result.size(), 'Must be returned one record');
    }

    @IsTest
    static void getRLABasedOnCaseIdNullInputTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnCaseId(null);
      }
      Test.stopTest();
      Assert.areEqual(0, result.size(), 'No record found as Name is a mandatory field and can not be null');
      }

    @IsTest
    static void getRLABasedOnMortgageAccNumberNullInputTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnMortgageAccNumber(null);
      }
      Test.stopTest();
      Assert.isTrue(result.size() > 0, 'Record can be one or more as this is not a mandatory field');
    }

    @IsTest
    static void getRLABasedOnCaseIdInvalidDataTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnCaseId('00000000001');
      }
      Test.stopTest();
      Assert.areEqual(0, result.size(), 'No record found');
    }

    @IsTest
    static void getRLABasedOnMortgageAccNumberInvalidDataTest() {
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(allowedUser) {
        result = hmFlexiSearchServiceObj.getRLABasedOnMortgageAccNumber('00000000001');
      }
      Test.stopTest();
      Assert.areEqual(0, result.size(), 'No record found');
    }

    @IsTest
    static void getRLABasedOnCaseIdForInvalidUserTest() {
      User invalidUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertestMinimum@testorg.com' LIMIT 1];
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(invalidUser) {
        try {
          result = hmFlexiSearchServiceObj.getRLABasedOnCaseId('00000000001');
          Assert.fail('Expecting user with no access to fail.');
        } catch( Exception ex ) {
          Assert.isInstanceOfType(ex, System.QueryException.class, 'Expecting insufficient access exception');
        }
      }
      Test.stopTest();
      Assert.areEqual(0, result.size(), 'No record found');
    }

    @IsTest
    static void getRLABasedOnMortgageAccNumberForInvalidUserTest() {
      User invalidUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertestMinimum@testorg.com' LIMIT 1];
      List<ResidentialLoanApplication> result = new List<ResidentialLoanApplication>();
      Test.startTest();
      System.runAs(invalidUser) {
        try {
          result = hmFlexiSearchServiceObj.getRLABasedOnMortgageAccNumber('00000000001');
          Assert.fail('Expecting user with no access to fail.');
        } catch( Exception ex ) {
          Assert.isInstanceOfType(ex, System.QueryException.class, 'Expecting insufficient access exception');
        }
      }
      Test.stopTest();
      Assert.areEqual(0, result.size(), 'No record found');
    }

    @isTest
    public static void getSearchDetailsTest(){
      User allowedUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertest@testorg.com' LIMIT 1];
      HMTestDataFactory.addUserToPermmisionSet('Mortgage', allowedUser);
      HMTestDataFactory.addUserToPermmisionSet('PS007HMMortgageUnderwritingAppUI', allowedUser);
      HMTestDataFactory.assignCustomPermission('PS007HMMortgageUnderwritingAppUI', 'HMCaseIDSearch'); 
      List<HMFlexiSearchService.SearchType> result =  new List<HMFlexiSearchService.SearchType>();
        Test.startTest();
        System.runAs(allowedUser) {
          result = hmFlexiSearchServiceObj.getSearchTypes();
        }
        Assert.isTrue(result.size() > 0, 'Should be returned at least one record as custom permission was assigned');
        Test.stopTest();
    }

    @isTest
    public static void getSearchDetailsTestForInvalidUser(){
      User invalidUser = [SELECT Id FROM User WHERE Username = 'minaccessuser_underwrittertestMinimum@testorg.com' LIMIT 1];
      List<HMFlexiSearchService.SearchType> result =  new List<HMFlexiSearchService.SearchType>();
        Test.startTest();
        System.runAs(invalidUser) {
          result = hmFlexiSearchServiceObj.getSearchTypes();
        	}
          Assert.areEqual(0, result.size(), 'Result size should be zero as custom permission was not assigned');
        Test.stopTest();
    }
}