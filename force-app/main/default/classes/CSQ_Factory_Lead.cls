/**
 * Factory responsible for building Lead records from a submission wrapper.
 */
public with sharing class CSQ_Factory_Lead implements CSQ_Interface_LeadFactory {

    /**
     * Creates a Lead record (not inserted).
     *
     * @param submission Submission wrapper containing applicant + organization details.
     * @return Lead SObject ready for DML.
     */
    public Lead createLead(CSQ_WRP_ApplicationSubmission submission) {
        CSQ_WRP_ApplicationSubmission.Applicant applicant = submission == null ? null : submission.applicant;
        CSQ_WRP_ApplicationSubmission.Organization organization = submission == null ? null : submission.organization;

        Lead lead = new Lead();
        lead.FirstName = applicant == null ? null : applicant.givenName;
        lead.LastName = applicant == null ? null : applicant.familyName;
        lead.Company = organization == null ? null : organization.legalName;
        lead.Email = applicant == null ? null : applicant.emailAddress;
        lead.Phone = applicant == null ? null : applicant.phoneNumber;
        lead.FedTaxId__c = organization == null ? null : organization.taxId;
        lead.SourceType__c = submission == null ? null : submission.channel;
        return lead;
    }
}