/**
 * Public facade for application processing.
 *
 * Keeps controllers/webhooks thin and centralizes creation of the core processor.
 */
public with sharing class CSQ_Service_ApplicationProcessing {

    /**
     * Processes an application submission end-to-end.
     *
     * @param submission Normalized submission wrapper.
     * @return Outcome wrapper for UI/integration callers.
     */
    public static CSQ_WRP_ApplicationOutcome process(CSQ_WRP_ApplicationSubmission submission) {
        return new CSQ_Service_ApplicationProcessingCore().process(submission);
    }
}