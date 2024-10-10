List<HMQuestionJunction__c> junctions = [SELECT Id, HMQuestion__c, HMSection__c, HMVersion__c FROM HMQuestionJunction__c];
for (HMQuestionJunction__c junction : junctions) {
    junction.HMExternalQuestionId__c = junction.HMQuestion__c;
    junction.HMExternalSectionId__c = junction.HMSection__c;
    junction.HMExternalVersionId__c = junction.HMVersion__c;
}
update junctions;

update populateExternalIdsPerObject(HMQuestionVersion__c.SObjectType);
update populateExternalIdsPerObject(HMQuestionSection__c.SObjectType);
List<HMQuestion__c> questions = (List<HMQuestion__c>) populateExternalIdsPerObject(HMQuestion__c.SObjectType);
for (HMQuestion__c question : questions) {
    question.HMDependentQuestionExternalId__c = question.HMDependentQuestion__c;
}
update questions;


// Functions
void populateExternalIds(List<SObject> qmsRecords) {
    for (SObject qmsObject : qmsRecords) {
        qmsObject.put('HMExternalId__c', qmsObject.Id);
    }
}

List<SObject> populateExternalIdsPerObject(SObjectType objectType) {
    Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();
    List<String> fieldNames = new List<String>(fieldsMap.keySet());
    String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + objectType.getDescribe().getName();
    List<SObject> qmsRecords = Database.query(query);
    populateExternalIds(qmsRecords);
    return qmsRecords;
}