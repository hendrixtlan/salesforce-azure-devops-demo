import { createElement } from 'lwc';
import CaseEscalationPanel from 'c/caseEscalationPanel';

function flushPromises() {
    return Promise.resolve();
}

describe('c-case-escalation-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders critical escalation details and warning', async () => {
        const element = createElement('c-case-escalation-panel', {
            is: CaseEscalationPanel
        });
        element.escalationLevel = 'Critical';
        element.priority = 'High';
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector('[data-id="level"]').textContent).toBe('Critical');
        expect(element.shadowRoot.querySelector('[data-id="priority"]').textContent).toBe('High');
        expect(element.shadowRoot.querySelector('[data-id="critical-message"]')).not.toBeNull();
    });

    it('does not render the warning for a standard case', async () => {
        const element = createElement('c-case-escalation-panel', {
            is: CaseEscalationPanel
        });
        element.escalationLevel = 'Standard';
        element.priority = 'Low';
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector('[data-id="critical-message"]')).toBeNull();
    });
});
