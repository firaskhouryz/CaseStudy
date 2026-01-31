/**
 * External webhook endpoint for creating applications.
 *
 * Accepts JSON payloads, validates content type/body, maps the payload to the internal
 * submission wrapper, and returns a normalized response.
 */
@RestResource(urlMapping='/cloudsquare/external/applications')
global with sharing class CSQ_APEX_ApplicationWebhook {

    @HttpPost
    /**
     * Handles webhook POST requests.
     *
     * @return Webhook response containing ok/userMessage and optional created record metadata.
     */
    global static CSQ_WRP_WebhookResponse post() {
        CSQ_WRP_WebhookResponse response = new CSQ_WRP_WebhookResponse();
        RestRequest request = RestContext.request;

        String contentType = request.headers == null ? null : request.headers.get('Content-Type');
        if (String.isNotBlank(contentType) && !contentType.toLowerCase().contains('application/json')) {
            return error(response, 415, 'Content-Type must be application/json.');
        }

        String body = request.requestBody == null ? null : request.requestBody.toString();
        if (String.isBlank(body)) {
            return error(response, 400, 'Missing request body.');
        }

        CSQ_WRP_WebhookApplicationPayload payload;
        try {
            payload = (CSQ_WRP_WebhookApplicationPayload) JSON.deserialize(body, CSQ_WRP_WebhookApplicationPayload.class);
        } catch (System.JSONException je) {
            return error(response, 400, 'Invalid JSON payload.');
        }

        if (payload == null) {
            return error(response, 400, 'Invalid JSON payload.');
        }

        CSQ_WRP_ApplicationSubmission submission = new CSQ_WRP_ApplicationSubmission();
        submission.channel = 'Webhook';

        if (payload.organization != null) {
            submission.organization = new CSQ_WRP_ApplicationSubmission.Organization();
            submission.organization.legalName = payload.organization.legalName;
            submission.organization.taxId = payload.organization.taxId;
        }

        if (payload.applicant != null) {
            submission.applicant = new CSQ_WRP_ApplicationSubmission.Applicant();
            submission.applicant.givenName = payload.applicant.givenName;
            submission.applicant.familyName = payload.applicant.familyName;
            submission.applicant.emailAddress = payload.applicant.emailAddress;
            submission.applicant.phoneNumber = payload.applicant.phoneNumber;
        }

        if (payload.financials != null) {
            submission.financials = new CSQ_WRP_ApplicationSubmission.FinancialSnapshot();
            submission.financials.annualRevenue = payload.financials.annualRevenue;
        }

        try {
            CSQ_WRP_ApplicationOutcome outcome = CSQ_Service_ApplicationProcessing.process(submission);
            applyOutcome(response, outcome);

            RestContext.response.statusCode = outcome.ok ? 200 : 400;
            return response;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Webhook post failed: ' + e.getMessage());
            return error(response, 500, 'Something went wrong while processing the request.');
        }
    }

    /**
     * Builds a standardized error response and sets the HTTP status code.
     *
     * @param response Response wrapper to populate.
     * @param statusCode HTTP status code to return.
     * @param message Friendly error message for the caller.
     * @return Populated response wrapper.
     */
    private static CSQ_WRP_WebhookResponse error(CSQ_WRP_WebhookResponse response, Integer statusCode, String message) {
        RestContext.response.statusCode = statusCode;
        response.ok = false;
        response.userMessage = message;
        return response;
    }

    /**
     * Maps the internal processing outcome onto the webhook response.
     *
     * @param response Webhook response wrapper to populate.
     * @param outcome Processing outcome returned by the core service.
     */
    private static void applyOutcome(CSQ_WRP_WebhookResponse response, CSQ_WRP_ApplicationOutcome outcome) {
        response.ok = outcome.ok;
        response.userMessage = outcome.userMessage;

        if (outcome.created != null) {
            response.created = new CSQ_WRP_WebhookResponse.CreatedRecord();
            response.created.sObjectType = outcome.created.sObjectType;
        }
    }
}