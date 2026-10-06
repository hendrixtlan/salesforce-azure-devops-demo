trigger CaseEscalationTrigger on Case (before insert, before update) {
    CaseEscalationService.applyPriority(Trigger.new);
}
