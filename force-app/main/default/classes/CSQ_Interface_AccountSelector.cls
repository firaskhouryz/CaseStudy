/**
 * Contract for locating an existing Account based on submission data.
 */
public interface CSQ_Interface_AccountSelector {

    /**
     * Finds a matching Account.
     *
     * @param federalTaxId Federal tax id (preferred match key when present).
     * @param companyName Company legal name (fallback match key).
     * @return Account record (at least Id populated) or null.
     */
    Account findMatch(String federalTaxId, String companyName);
}