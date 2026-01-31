/**
 * Contract for creating Lead records from a submission.
 */
public interface CSQ_Interface_LeadFactory {

    /**
     * Creates a Lead (not inserted).
     *
     * @param submission Submission wrapper.
     * @return Lead record ready for DML.
     */
    Lead createLead(CSQ_WRP_ApplicationSubmission submission);
}