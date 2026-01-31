/**
 * Webhook response wrapper returned by the Apex REST endpoint.
 *
 * Note: Record Ids are intentionally not returned.
 */
global class CSQ_WRP_WebhookResponse {
    global Boolean ok;
    global CreatedRecord created;
    global String userMessage;

    /** Metadata about what kind of record was created. */
    global class CreatedRecord {
        global String sObjectType;
    }
}