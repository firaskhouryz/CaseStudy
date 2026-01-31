/**
 * Contract for grouping DML operations.
 */
public interface CSQ_Interface_UnitOfWork {

    /**
     * Registers a record to be inserted on commit.
     *
     * @param record SObject to insert.
     */
    void registerNew(SObject record);

    /**
     * Commits all registered work.
     */
    void commitWork();
}