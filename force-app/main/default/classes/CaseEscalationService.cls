public with sharing class CaseEscalationService {
    public static void applyPriority(List<Case> casesToProcess) {
        for (Case caseRecord : casesToProcess) {
            if (caseRecord.Escalation_Level__c == 'Critical') {
                caseRecord.Priority = 'High';
            } else if (caseRecord.Escalation_Level__c == 'Priority' && caseRecord.Priority == null) {
                caseRecord.Priority = 'Medium';
            }
        }
    }
}
