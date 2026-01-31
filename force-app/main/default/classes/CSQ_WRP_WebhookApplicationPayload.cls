/**
 * External webhook request payload.
 *
 * This is separate from the internal submission wrapper to allow the inbound
 * schema to evolve independently.
 */
global class CSQ_WRP_WebhookApplicationPayload {
    global Organization organization;
    global Applicant applicant;
    global FinancialSnapshot financials;

    /** Organization section of the inbound payload. */
    global class Organization {
        global String legalName;
        global String taxId;
    }

    /** Applicant/contact section of the inbound payload. */
    global class Applicant {
        global String givenName;
        global String familyName;
        global String emailAddress;
        global String phoneNumber;
    }

    /** Optional financial section of the inbound payload. */
    global class FinancialSnapshot {
        global Decimal annualRevenue;
    }
}