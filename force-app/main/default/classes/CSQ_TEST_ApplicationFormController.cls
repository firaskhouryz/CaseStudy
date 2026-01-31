/**
 * Unit tests for the Community/Portal controller entry point.
 */
@IsTest
private class CSQ_TEST_ApplicationFormController {

    /**
     * Builds a fully valid submission wrapper for portal/controller tests.
     *
     * @param companyName Company name to set on the submission.
     * @return A valid CSQ_WRP_ApplicationSubmission instance.
     */
    private static CSQ_WRP_ApplicationSubmission newValidSubmission(String companyName) {
        CSQ_WRP_ApplicationSubmission submission = new CSQ_WRP_ApplicationSubmission();
        submission.organization = new CSQ_WRP_ApplicationSubmission.Organization();
        submission.organization.legalName = companyName;
        submission.organization.taxId = null;

        submission.applicant = new CSQ_WRP_ApplicationSubmission.Applicant();
        submission.applicant.givenName = 'Portal';
        submission.applicant.familyName = 'User';
        submission.applicant.emailAddress = 'portal.user@example.com';
        submission.applicant.phoneNumber = '+1 555 0200';

        submission.financials = new CSQ_WRP_ApplicationSubmission.FinancialSnapshot();
        submission.financials.annualRevenue = null;

        return submission;
    }

    @IsTest
    /** Verifies required-field validation returns a friendly message. */
    static void portal_allFieldsMissing_returnsFailure() {
        CSQ_WRP_ApplicationSubmission submission = new CSQ_WRP_ApplicationSubmission();

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_APEX_ApplicationFormController.submit(submission);
        Test.stopTest();

        System.assertEquals(false, outcome.ok);
        System.assertNotEquals(null, outcome.userMessage);
        System.assert(outcome.userMessage.startsWith('Missing required fields:'), 'Should return validation message');
        System.assert(outcome.userMessage.contains('Company Name'));
        System.assert(outcome.userMessage.contains('Contact First Name'));
        System.assert(outcome.userMessage.contains('Contact Last Name'));
        System.assert(outcome.userMessage.contains('Email'));
        System.assert(outcome.userMessage.contains('Phone'));
        System.assertEquals(null, outcome.created);
    }

    @IsTest
    /** Verifies partial required-field validation returns missing field names. */
    static void portal_oneOrTwoFieldsMissing_returnsFailure() {
        CSQ_WRP_ApplicationSubmission submission = new CSQ_WRP_ApplicationSubmission();
        submission.organization = new CSQ_WRP_ApplicationSubmission.Organization();
        submission.organization.legalName = 'Partial Co';

        submission.applicant = new CSQ_WRP_ApplicationSubmission.Applicant();
        submission.applicant.givenName = 'Partial';
        submission.applicant.familyName = 'User';
        // missing email + phone

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_APEX_ApplicationFormController.submit(submission);
        Test.stopTest();

        System.assertEquals(false, outcome.ok);
        System.assert(outcome.userMessage != null && outcome.userMessage.startsWith('Missing required fields:'), 'Should return validation message');
        System.assert(outcome.userMessage.contains('Email'));
        System.assert(outcome.userMessage.contains('Phone'));
        System.assertEquals(null, outcome.created);
    }

    @IsTest
    /** Verifies Lead creation path is used when there is no Account match. */
    static void portal_leadCreation_whenNoAccountMatch() {
        CSQ_WRP_ApplicationSubmission submission = newValidSubmission('Portal Lead Co');
        submission.organization.taxId = 'CSQ-PORTAL-NO-MATCH';

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_APEX_ApplicationFormController.submit(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Lead', outcome.created.sObjectType);

        Lead createdLead = [
            SELECT Id, SourceType__c, Email
            FROM Lead
            WHERE Email = :submission.applicant.emailAddress
            LIMIT 1
        ];
        System.assertEquals('Community', createdLead.SourceType__c);
    }

    @IsTest
    /** Verifies Opportunity creation path is used when Account matches by name. */
    static void portal_opportunityCreation_matchedByAccountName() {
        Account acc = new Account(Name = 'Portal Name Match');
        insert acc;

        CSQ_WRP_ApplicationSubmission submission = newValidSubmission('Portal Name Match');
        submission.organization.taxId = null;

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_APEX_ApplicationFormController.submit(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Opportunity', outcome.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'Community'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Community', opp.SourceType__c);
    }

    @IsTest
    /** Verifies Opportunity creation path is used when Account matches by tax id. */
    static void portal_opportunityCreation_matchedByTaxId() {
        Account acc = new Account(Name = 'Portal Tax Match', FedTaxId__c = 'PORTAL-TAX-123');
        insert acc;

        CSQ_WRP_ApplicationSubmission submission = newValidSubmission('Does Not Matter');
        submission.organization.taxId = 'PORTAL-TAX-123';

        Test.startTest();
        CSQ_WRP_ApplicationOutcome outcome = CSQ_APEX_ApplicationFormController.submit(submission);
        Test.stopTest();

        System.assertEquals(true, outcome.ok);
        System.assertNotEquals(null, outcome.created);
        System.assertEquals('Opportunity', outcome.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'Community'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Community', opp.SourceType__c);
    }
}