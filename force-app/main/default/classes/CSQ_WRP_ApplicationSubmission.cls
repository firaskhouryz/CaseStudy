/**
 * UI/webhook submission wrapper used by the controller and processing services.
 *
 * This wrapper is intentionally structured as nested objects to keep the payload
 * readable and to match how the LWC/webhook send data.
 */
public class CSQ_WRP_ApplicationSubmission {

    @AuraEnabled public Organization organization { get; set; }
    @AuraEnabled public Applicant applicant { get; set; }
    @AuraEnabled public FinancialSnapshot financials { get; set; }
    @AuraEnabled public String channel { get; set; } // Community or Webhook

    /** Company/organization details. */
    public class Organization {
        @AuraEnabled public String legalName { get; set; }
        @AuraEnabled public String taxId { get; set; }
    }

    /** Primary applicant/contact details. */
    public class Applicant {
        @AuraEnabled public String givenName { get; set; }
        @AuraEnabled public String familyName { get; set; }
        @AuraEnabled public String emailAddress { get; set; }
        @AuraEnabled public String phoneNumber { get; set; }
    }

    /** Optional financial snapshot information. */
    public class FinancialSnapshot {
        @AuraEnabled public Decimal annualRevenue { get; set; }
    }
}