/**
 * Factory responsible for building Opportunity records from a submission wrapper.
 */
public with sharing class CSQ_Factory_Opportunity implements CSQ_Interface_OpportunityFactory {

    /**
     * Creates an Opportunity record (not inserted).
     *
     * @param submission Submission wrapper.
     * @param accountId Account Id to relate the Opportunity to.
     * @return Opportunity SObject ready for DML.
     */
    public Opportunity createOpportunity(CSQ_WRP_ApplicationSubmission submission, Id accountId) {
        CSQ_WRP_ApplicationSubmission.Organization organization = submission == null ? null : submission.organization;
        DateTime now = DateTime.now();
        Opportunity opportunity = new Opportunity();
        opportunity.Name = (organization == null ? null : organization.legalName) + '-' + String.valueOf(now.getTime());
        opportunity.StageName = 'Prospecting';
        opportunity.CloseDate = Date.today().addDays(20);
        opportunity.AccountId = accountId;
        opportunity.SourceType__c = submission == null ? null : submission.channel;
        return opportunity;
    }
}