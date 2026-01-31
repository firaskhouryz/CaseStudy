/**
 * Contract for creating Opportunity records from a submission.
 */
public interface CSQ_Interface_OpportunityFactory {

    /**
     * Creates an Opportunity (not inserted).
     *
     * @param submission Submission wrapper.
     * @param accountId Related Account Id.
     * @return Opportunity record ready for DML.
     */
    Opportunity createOpportunity(CSQ_WRP_ApplicationSubmission submission, Id accountId);
}