/**
 * Core orchestration service for application processing.
 *
 * Flow:
 * 1) Validate submission
 * 2) Attempt Account match
 * 3) Create Opportunity (if matched) or Lead (if not)
 * 4) Commit via Unit of Work
 *
 * Note: This service intentionally does not return record Ids in the response.
 */
public without sharing class CSQ_Service_ApplicationProcessingCore implements CSQ_IApplicationProcessing {
    private static final String RECORD_TYPE_OPPORTUNITY = 'Opportunity';
    private static final String RECORD_TYPE_LEAD = 'Lead';

    private static final String MESSAGE_SUCCESS = 'Application received.';
    private static final String MESSAGE_TRY_AGAIN = 'We could not process your application right now. Please try again.';

    private final CSQ_Interface_AccountSelector accountSelector;
    private final CSQ_Interface_LeadFactory leadFactory;
    private final CSQ_Interface_OpportunityFactory opportunityFactory;
    private final CSQ_Interface_UnitOfWork unitOfWork;
    private final CSQ_Validator_ApplicationSubmission validator;

    /**
     * Default constructor that wires concrete implementations.
     */
    public CSQ_Service_ApplicationProcessingCore() {
        this(
            new CSQ_Selector_AccountMatch(),
            new CSQ_Factory_Lead(),
            new CSQ_Factory_Opportunity(),
            new CSQ_UOW_Dml(),
            new CSQ_Validator_ApplicationSubmission()
        );
    }

    public CSQ_Service_ApplicationProcessingCore(
        CSQ_Interface_AccountSelector accountSelector,
        CSQ_Interface_LeadFactory leadFactory,
        CSQ_Interface_OpportunityFactory opportunityFactory,
        CSQ_Interface_UnitOfWork unitOfWork,
        CSQ_Validator_ApplicationSubmission validator
    ) {
        this.accountSelector = accountSelector;
        this.leadFactory = leadFactory;
        this.opportunityFactory = opportunityFactory;
        this.unitOfWork = unitOfWork;
        this.validator = validator;
    }

    /**
     * Processes a submission and returns a safe outcome for UI/integration callers.
     *
     * @param submission Submission wrapper.
     * @return Outcome wrapper indicating success/failure and a userMessage.
     */
    public CSQ_WRP_ApplicationOutcome process(CSQ_WRP_ApplicationSubmission submission) {
        try {
            validator.validate(submission);

            String taxId = submission.organization == null ? null : submission.organization.taxId;
            String legalName = submission.organization == null ? null : submission.organization.legalName;
            system.debug(LoggingLevel.INFO, 'Attempting Account match for Tax ID: ' + taxId + ', Legal Name: ' + legalName);
            Account matchedAccount = accountSelector.findMatch(taxId, legalName);

            if (matchedAccount != null) {
                Opportunity opportunity = opportunityFactory.createOpportunity(submission, matchedAccount.Id);
                unitOfWork.registerNew(opportunity);
                unitOfWork.commitWork();

                return success(RECORD_TYPE_OPPORTUNITY);
            }

            Lead lead = leadFactory.createLead(submission);
            unitOfWork.registerNew(lead);
            unitOfWork.commitWork();

            return success(RECORD_TYPE_LEAD);

        } catch (CSQ_ApplicationValidationException ve) {
            return failure(ve.getMessage());

        } catch (DmlException dmle) {
            System.debug(LoggingLevel.ERROR, 'Application processing DML failed: ' + dmle.getMessage());
            return failure(MESSAGE_TRY_AGAIN);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Application processing failed: ' + e.getMessage());
            return failure(MESSAGE_TRY_AGAIN);
        }
    }

    /**
     * Creates a success outcome. Includes record type metadata, but not the record Id.
     *
     * @param recordType 'Lead' or 'Opportunity'.
     * @return Outcome wrapper with ok=true.
     */
    private static CSQ_WRP_ApplicationOutcome success(String recordType) {
        CSQ_WRP_ApplicationOutcome outcome = new CSQ_WRP_ApplicationOutcome();
        outcome.ok = true;
        outcome.userMessage = MESSAGE_SUCCESS;

        outcome.created = new CSQ_WRP_ApplicationOutcome.CreatedRecord();
        outcome.created.sObjectType = recordType;
        return outcome;
    }

    /**
     * Creates a failure outcome.
     *
     * @param message Friendly error message.
     * @return Outcome wrapper with ok=false.
     */
    private static CSQ_WRP_ApplicationOutcome failure(String message) {
        CSQ_WRP_ApplicationOutcome outcome = new CSQ_WRP_ApplicationOutcome();
        outcome.ok = false;
        outcome.userMessage = message;
        return outcome;
    }
}