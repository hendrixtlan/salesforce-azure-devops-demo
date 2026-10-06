import { LightningElement, api } from 'lwc';

export default class CaseEscalationPanel extends LightningElement {
    @api escalationLevel = 'Standard';
    @api priority = 'Medium';

    get isCritical() {
        return this.escalationLevel === 'Critical';
    }
}
