/**
 * Minimal Unit of Work implementation for grouping DML operations.
 *
 * This implementation only supports inserting new records (registerNew + commitWork).
 */
public without sharing class CSQ_UOW_Dml implements CSQ_Interface_UnitOfWork {
    private final List<SObject> newRecords = new List<SObject>();

    /**
     * Registers a record to be inserted on commit.
     *
     * @param record SObject to insert.
     */
    public void registerNew(SObject record) {
        if (record == null) return;
        newRecords.add(record);
    }

    /**
     * Commits all registered records as a single insert.
     */
    public void commitWork() {
        if (newRecords.isEmpty()) return;
        insert newRecords;
        newRecords.clear();
    }
}