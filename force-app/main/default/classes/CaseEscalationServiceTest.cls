@IsTest
private class CaseEscalationServiceTest {
    @IsTest
    static void criticalCaseRunsProgrammaticAndDeclarativeAutomation() {
        CaseEscalationService.featureEnabledOverride = true;

        Case caseRecord = new Case(
            Subject = 'Production payment issue',
            Status = 'New',
            Origin = 'Web',
            Escalation_Level__c = 'Critical',
            Priority = 'Low'
        );

        insert caseRecord;

        Case actual = [
            SELECT Priority, Escalation_Level__c, Escalation_Source__c
            FROM Case
            WHERE Id = :caseRecord.Id
        ];

        System.assertEquals('High', actual.Priority);
        System.assertEquals('Critical', actual.Escalation_Level__c);
        System.assertEquals('Record-Triggered Flow', actual.Escalation_Source__c);
    }

    @IsTest
    static void featureFlagCanDisableProgrammaticPriorityAutomation() {
        CaseEscalationService.featureEnabledOverride = false;

        Case caseRecord = new Case(
            Subject = 'Controlled rollout validation',
            Status = 'New',
            Origin = 'Web',
            Escalation_Level__c = 'Critical',
            Priority = 'Low'
        );

        insert caseRecord;

        Case actual = [SELECT Priority, Escalation_Source__c FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('Low', actual.Priority);
        System.assertEquals('Record-Triggered Flow', actual.Escalation_Source__c);
    }

    @IsTest
    static void standardCaseKeepsDefaultPriority() {
        CaseEscalationService.featureEnabledOverride = true;

        Case caseRecord = new Case(
            Subject = 'General question',
            Status = 'New',
            Origin = 'Phone',
            Escalation_Level__c = 'Standard',
            Priority = 'Low'
        );

        insert caseRecord;

        Case actual = [SELECT Priority, Escalation_Source__c FROM Case WHERE Id = :caseRecord.Id];
        System.assertEquals('Low', actual.Priority);
        System.assertEquals(null, actual.Escalation_Source__c);
    }
}
