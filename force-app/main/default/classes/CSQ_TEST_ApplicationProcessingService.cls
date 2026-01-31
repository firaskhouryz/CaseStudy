/**
 * Unit tests for the application processing facade + core orchestration.
 */
@IsTest
private class CSQ_TEST_ApplicationProcessingService {

    /**
     * Builds a submission wrapper for service-level tests.
     *
     * @param companyName Organization legal name.
     * @return A populated submission wrapper.
     */
    private static CSQ_WRP_ApplicationSubmission newSubmission(String companyName) {
        CSQ_WRP_ApplicationSubmission submission = new CSQ_WRP_ApplicationSubmission();
        submission.organization = new CSQ_WRP_ApplicationSubmission.Organization();
        submission.organization.legalName = companyName;

        submission.applicant = new CSQ_WRP_ApplicationSubmission.Applicant();
        submission.applicant.givenName = 'Test';
        submission.applicant.familyName = 'User';
        submission.applicant.emailAddress = 'test.user@example.com';
        submission.applicant.phoneNumber = '+1 555 0100';

        submission.channel = 'UnitTest';
        return submission;
    }

    @IsTest
    /** Verifies the service creates a Lead when no Account match is found. */
    static void service_createsLead_whenNoAccountMatch() {
        CSQ_WRP_ApplicationSubmission submission = newSubmission('No Match Co');
        submission.organization.taxId = 'CSQ-NO-MATCH';

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_Service_ApplicationProcessing.process(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Lead', outcome.created.sObjectType);

        Lead createdLead = [
            SELECT Id, SourceType__c, Email, FedTaxId__c
            FROM Lead
            WHERE Email = :submission.applicant.emailAddress
            LIMIT 1
        ];
        System.assertEquals('UnitTest', createdLead.SourceType__c);
        System.assertEquals('CSQ-NO-MATCH', createdLead.FedTaxId__c);
    }

    @IsTest
    /** Verifies the service creates an Opportunity when matching by tax id. */
    static void service_createsOpportunity_whenMatchedByFederalTaxId() {
        Account acc = new Account(Name = 'Tax Match Co', FedTaxId__c = 'TAX-123');
        insert acc;

        CSQ_WRP_ApplicationSubmission submission = newSubmission('Does Not Matter');
        submission.organization.taxId = 'TAX-123';

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_Service_ApplicationProcessing.process(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Opportunity', outcome.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'UnitTest'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
    }

    @IsTest
    /** Verifies the service creates an Opportunity when matching by company name. */
    static void service_createsOpportunity_whenMatchedByCompanyName() {
        Account acc = new Account(Name = 'Name Match Co');
        insert acc;

        CSQ_WRP_ApplicationSubmission submission = newSubmission('Name Match Co');
        submission.organization.taxId = null;

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_Service_ApplicationProcessing.process(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Opportunity', outcome.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'UnitTest'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
    }
}