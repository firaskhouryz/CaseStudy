/**
 * Account selector used to find an existing Account based on the submission.
 *
 * Matching rules (simple and explicit for the exercise):
 * - Prefer Federal Tax Id match if provided
 * - Otherwise try exact Account.Name match
 */
public without sharing class CSQ_Selector_AccountMatch implements CSQ_Interface_AccountSelector {

    /**
     * Attempts to find an Account match using tax id or company name.
     *
     * @param federalTaxId Federal Tax Id value.
     * @param companyName Company legal name.
     * @return Matched Account (Id populated) or null when not found.
     */
    public Account findMatch(String federalTaxId, String companyName) {
        if (String.isNotBlank(federalTaxId)) {
            List<Account> matches = [
                SELECT Id
                FROM Account
                WHERE FedTaxId__c = :federalTaxId
                LIMIT 1
            ];
            return matches.isEmpty() ? null : matches[0];
        }

        // Exact name match per exercise scope; fuzzy matching can be added if required.
        if (String.isNotBlank(companyName)) {
            List<Account> matches = [
                SELECT Id
                FROM Account
                WHERE Name = :companyName
                LIMIT 1
            ];
            return matches.isEmpty() ? null : matches[0];
        }

        return null;
    }
}