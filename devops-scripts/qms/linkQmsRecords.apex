List<HMQuestion__c> questions = [
        SELECT Id, HMDependentQuestionExternalId__c
        FROM HMQuestion__c
        WHERE HMDependentQuestionExternalId__c != NULL
];
for (HMQuestion__c question : questions) {
    question.HMDependentQuestion__r = new HMQuestion__c(HMExternalId__c = question.HMDependentQuestionExternalId__c);
}
update questions;

StaticResource qmsResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'QMS_Junctions'];
List<HMQuestionJunction__c> junctions =
        ((Map<String, List<HMQuestionJunction__c>>)JSON.deserialize(
                qmsResource.Body.toString(), Map<String, List<HMQuestionJunction__c>>.class
        )).get('records');
for (HMQuestionJunction__c junction : junctions) {
    junction.HMQuestion__r = new HMQuestion__c(HMExternalId__c = junction.HMExternalQuestionId__c);
    junction.HMSection__r = new HMQuestionSection__c(HMExternalId__c = junction.HMExternalSectionId__c);
    junction.HMVersion__r = new HMQuestionVersion__c(HMExternalId__c = junction.HMExternalVersionId__c);
}
insert junctions;

// Cleanup unlinked records
delete [SELECT Id FROM HMQuestion__c WHERE Id NOT IN (SELECT HMQuestion__c FROM HMQuestionJunction__c)];
delete [SELECT Id FROM HMQuestionSection__c WHERE Id NOT IN (SELECT HMSection__c FROM HMQuestionJunction__c)];
delete [SELECT Id FROM HMQuestionVersion__c WHERE Id NOT IN (SELECT HMVersion__c FROM HMQuestionJunction__c)];