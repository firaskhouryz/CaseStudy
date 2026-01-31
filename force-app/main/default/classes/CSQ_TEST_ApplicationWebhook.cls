/**
 * Unit tests for the Apex REST webhook endpoint.
 */
@IsTest
private class CSQ_TEST_ApplicationWebhook {

    /**
     * Creates and installs a RestRequest/RestResponse into RestContext.
     *
     * @param contentType Content-Type header value.
     * @param body JSON string body.
     */
    private static void setRequest(String contentType, String body) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/cloudsquare/external/applications';
        req.httpMethod = 'POST';

        if (contentType != null) {
            req.addHeader('Content-Type', contentType);
        }

        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }

        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    /**
     * Builds a valid JSON request body.
     *
     * @param companyName Organization legal name.
     * @param taxId Optional tax id.
     * @return JSON string payload.
     */
    private static String validBody(String companyName, String taxId) {
        String taxPart = taxId == null ? '' : (', "taxId": "' + taxId + '"');
        return '{' +
            '"organization": {' +
                '"legalName": "' + companyName + '"' + taxPart +
            '},' +
            '"applicant": {' +
                '"givenName": "Web",' +
                '"familyName": "Hook",' +
                '"emailAddress": "web.hook@example.com",' +
                '"phoneNumber": "+1 555 0300"' +
            '}' +
        '}';
    }

    @IsTest
    /** Verifies webhook validates required fields and returns 400. */
    static void webhook_allFieldsMissing_returns400() {
        setRequest('application/json', '{}');

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.ok);
        System.assert(res.userMessage != null && res.userMessage.startsWith('Missing required fields:'), 'Should return validation message');
        System.assert(res.userMessage.contains('Company Name'));
        System.assert(res.userMessage.contains('Contact First Name'));
        System.assert(res.userMessage.contains('Contact Last Name'));
        System.assert(res.userMessage.contains('Email'));
        System.assert(res.userMessage.contains('Phone'));
    }

    @IsTest
    /** Verifies webhook returns 400 when a subset of required fields are missing. */
    static void webhook_oneOrTwoFieldsMissing_returns400() {
        setRequest('application/json', '{' +
            '"organization": {' +
                '"legalName": "Webhook Partial"' +
            '},' +
            '"applicant": {' +
                '"givenName": "Web",' +
                '"familyName": "Hook",' +
                '"emailAddress": "web.hook@example.com"' +
            '}' +
        '}');

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.ok);
        System.assert(res.userMessage != null && res.userMessage.startsWith('Missing required fields:'), 'Should return validation message');
        System.assert(res.userMessage.contains('Phone'));
    }

    @IsTest
    /** Verifies webhook returns 415 for non-JSON content types. */
    static void webhook_invalidHeader_returns415() {
        setRequest('text/plain', validBody('Webhook Lead Co', null));

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(415, RestContext.response.statusCode);
        System.assertEquals(false, res.ok);
        System.assertEquals('Content-Type must be application/json.', res.userMessage);
    }

    @IsTest
    /** Verifies webhook returns 400 for malformed JSON. */
    static void webhook_invalidJson_returns400() {
        setRequest('application/json', '{');

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.ok);
        System.assertEquals('Invalid JSON payload.', res.userMessage);
    }

    @IsTest
    /** Verifies webhook returns 400 when request body is missing. */
    static void webhook_nullBody_returns400() {
        setRequest('application/json', null);

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(false, res.ok);
        System.assertEquals('Missing request body.', res.userMessage);
    }

    @IsTest
    /** Verifies Lead creation path from webhook when no Account match exists. */
    static void webhook_leadCreation_whenNoAccountMatch() {
        setRequest('application/json', validBody('Webhook Lead Co', 'CSQ-WEBHOOK-NO-MATCH'));

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, res.ok);
        System.assertNotEquals(null, res.created);
        System.assertEquals('Lead', res.created.sObjectType);

        Lead lead = [
            SELECT Id, SourceType__c, Email
            FROM Lead
            WHERE Email = 'web.hook@example.com'
            LIMIT 1
        ];
        System.assertEquals('Webhook', lead.SourceType__c);
    }

    @IsTest
    /** Verifies Opportunity creation path from webhook when matching by company name. */
    static void webhook_opportunityCreation_matchedByCompanyName() {
        Account acc = new Account(Name = 'Webhook Name Match');
        insert acc;

        setRequest('application/json', validBody('Webhook Name Match', null));

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, res.ok);
        System.assertNotEquals(null, res.created);
        System.assertEquals('Opportunity', res.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'Webhook'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Webhook', opp.SourceType__c);
    }

    @IsTest
    /** Verifies Opportunity creation path from webhook when matching by tax id. */
    static void webhook_opportunityCreation_matchedByFederalTaxId() {
        Account acc = new Account(Name = 'Webhook Tax Match', FedTaxId__c = 'WEBHOOK-TAX-123');
        insert acc;

        setRequest('application/json', validBody('Does Not Matter', 'WEBHOOK-TAX-123'));

        Test.startTest();
        CSQ_WRP_WebhookResponse res = CSQ_APEX_ApplicationWebhook.post();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, res.ok);
        System.assertNotEquals(null, res.created);
        System.assertEquals('Opportunity', res.created.sObjectType);

        Opportunity opp = [
            SELECT Id, AccountId, SourceType__c
            FROM Opportunity
            WHERE AccountId = :acc.Id AND SourceType__c = 'Webhook'
            LIMIT 1
        ];
        System.assertEquals(acc.Id, opp.AccountId);
        System.assertEquals('Webhook', opp.SourceType__c);
    }
}