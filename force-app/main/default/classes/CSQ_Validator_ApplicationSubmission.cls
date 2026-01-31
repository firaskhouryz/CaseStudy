/**
 * Validates incoming application submissions.
 *
 * This validator focuses on presence/required-field checks and throws a
 * CSQ_ApplicationValidationException with a user-friendly message.
 */
public with sharing class CSQ_Validator_ApplicationSubmission {

    /**
     * Validates required fields and throws on failure.
     *
     * @param submission Submission wrapper to validate.
     * @throws CSQ_ApplicationValidationException When required fields are missing.
     */
    public void validate(CSQ_WRP_ApplicationSubmission submission) {
        if (submission == null) {
            throw new CSQ_ApplicationValidationException('Please provide an application.');
        }

        List<String> missing = new List<String>();

        if (submission.organization == null || String.isBlank(submission.organization.legalName)) missing.add('Company Name');
        if (submission.applicant == null || String.isBlank(submission.applicant.givenName)) missing.add('Contact First Name');
        if (submission.applicant == null || String.isBlank(submission.applicant.familyName)) missing.add('Contact Last Name');
        if (submission.applicant == null || String.isBlank(submission.applicant.emailAddress)) missing.add('Email');
        if (submission.applicant == null || String.isBlank(submission.applicant.phoneNumber)) missing.add('Phone');
        if (String.isBlank(submission.channel)) missing.add('Submission Channel');

        if (!missing.isEmpty()) {
            throw new CSQ_ApplicationValidationException('Missing required fields: ' + String.join(missing, ', ') + '.');
        }
    }
}