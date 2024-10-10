User u = new User();
u.Username = 'underwriter_test_user@sfdx.org.' + UserInfo.getOrganizationId();
u.FirstName = 'Underwriter';
u.LastName = 'QA';
u.Email = 'underwriter_test_user@sfdx.org';
u.Alias = 'underw';
u.TimeZoneSidKey = 'America/Denver';
u.LocaleSidKey = 'en_US';
u.EmailEncodingKey = 'UTF-8';
u.LanguageLocaleKey = 'en_US';
u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'HMUnderwriters'].Id;
insert u;
List<String> permSetNames = new List<String>{
        'Mortgage', 'BRERuntime', 'PS006HMMortgageApplicationData', 'PS007HMMortgageUnderwritingAppUI'
};
List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE Name IN :permSetNames];

List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
for (PermissionSet permSet : permSets) {
    PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
    permSetAssignment.AssigneeId = u.Id;
    permSetAssignment.PermissionSetId = permSet.Id;
    permSetAssignments.add(permSetAssignment);
}
insert permSetAssignments;
