/**
 * Community/Portal entry point for submitting an application from LWC.
 *
 * Responsibilities:
 * - Basic null-guarding and setting the submission channel.
 * - Delegating to the processing service.
 * - Returning user-friendly messages for UI consumption.
 */
public with sharing class CSQ_APEX_ApplicationFormController {

    @AuraEnabled
    /**
     * Submits an application from the UI.
     *
     * @param submission User-provided application payload (nested wrapper).
     * @return Outcome wrapper containing ok/userMessage and (optionally) created record metadata.
     */
    public static CSQ_WRP_ApplicationOutcome submit(CSQ_WRP_ApplicationSubmission submission) {
        if (submission == null) {
            return failure('Please fill out the application form.');
        }

        submission.channel = 'Community';

        try {
            return CSQ_Service_ApplicationProcessing.process(submission);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Portal submit failed: ' + e.getMessage());
            return failure('We could not submit your application right now. Please try again.');
        }
    }

    /**
     * Builds a standardized failure response for the UI.
     *
     * @param message Friendly message intended for display.
     * @return Outcome wrapper with ok=false.
     */
    private static CSQ_WRP_ApplicationOutcome failure(String message) {
        CSQ_WRP_ApplicationOutcome outcome = new CSQ_WRP_ApplicationOutcome();
        outcome.ok = false;
        outcome.userMessage = message;
        return outcome;
    }
}