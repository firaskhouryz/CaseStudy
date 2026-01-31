/**
 * Contract for processing an application submission.
 */
public interface CSQ_IApplicationProcessing {

    /**
     * Processes a submission and returns an outcome.
     *
     * @param submission Submission wrapper.
     * @return Outcome wrapper with ok/userMessage and optional created record metadata.
     */
    CSQ_WRP_ApplicationOutcome process(CSQ_WRP_ApplicationSubmission submission);
}