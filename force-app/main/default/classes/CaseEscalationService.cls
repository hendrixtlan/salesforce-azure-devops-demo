public with sharing class CaseEscalationService {
    @TestVisible
    private static Boolean featureEnabledOverride;

    public static void applyPriority(List<Case> casesToProcess) {
        if (!isPriorityAutomationEnabled()) {
            return;
        }

        for (Case caseRecord : casesToProcess) {
            if (caseRecord.Escalation_Level__c == 'Critical') {
                caseRecord.Priority = 'High';
            } else if (caseRecord.Escalation_Level__c == 'Priority' && caseRecord.Priority == null) {
                caseRecord.Priority = 'Medium';
            }
        }
    }

    private static Boolean isPriorityAutomationEnabled() {
        if (Test.isRunningTest() && featureEnabledOverride != null) {
            return featureEnabledOverride;
        }

        Case_Escalation_Config__mdt config = Case_Escalation_Config__mdt.getInstance('Default');
        return config != null && config.Priority_Automation_Enabled__c;
    }
}
