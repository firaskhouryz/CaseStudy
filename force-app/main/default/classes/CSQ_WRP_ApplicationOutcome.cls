/**
 * Standard response wrapper returned to the UI.
 *
 * Notes:
 * - created.sObjectType is set to 'Lead' or 'Opportunity' when a record is created.
 * - Record Ids are intentionally not returned/populated.
 */
public class CSQ_WRP_ApplicationOutcome {
    @AuraEnabled public Boolean ok { get; set; }
    @AuraEnabled public CreatedRecord created { get; set; }
    @AuraEnabled public String userMessage { get; set; }

    /** Metadata about what kind of record was created. */
    public class CreatedRecord {
        @AuraEnabled public String sObjectType { get; set; } // Lead or Opportunity
    }
}