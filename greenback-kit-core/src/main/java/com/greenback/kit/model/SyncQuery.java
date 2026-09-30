package com.greenback.kit.model;

import java.time.Instant;

import static com.greenback.kit.util.Utils.toIterable;

/**
 * Optional filters when listing syncs is supported by a deployment.
 * Public Greenback docs primarily expose create-under-account and get-by-id;
 * account expands ({@code syncs}) remain the common way to observe current syncs.
 */
public class SyncQuery extends Query<SyncQuery> {

    protected Iterable<String> accountIds;
    protected Iterable<SyncType> types;
    protected Iterable<ProcessingStatus> statuses;
    protected Instant minCreatedAt;
    protected Instant maxCreatedAt;

    public Iterable<String> getAccountIds() {
        return accountIds;
    }

    public SyncQuery setAccountIds(Iterable<String> accountIds) {
        this.accountIds = accountIds;
        return this;
    }

    public SyncQuery setAccountIds(String... accountIds) {
        return this.setAccountIds(toIterable(accountIds));
    }

    public Iterable<SyncType> getTypes() {
        return types;
    }

    public SyncQuery setTypes(Iterable<SyncType> types) {
        this.types = types;
        return this;
    }

    public SyncQuery setTypes(SyncType... types) {
        return this.setTypes(toIterable(types));
    }

    public Iterable<ProcessingStatus> getStatuses() {
        return statuses;
    }

    public SyncQuery setStatuses(Iterable<ProcessingStatus> statuses) {
        this.statuses = statuses;
        return this;
    }

    public SyncQuery setStatuses(ProcessingStatus... statuses) {
        return this.setStatuses(toIterable(statuses));
    }

    public Instant getMinCreatedAt() {
        return minCreatedAt;
    }

    public SyncQuery setMinCreatedAt(Instant minCreatedAt) {
        this.minCreatedAt = minCreatedAt;
        return this;
    }

    public Instant getMaxCreatedAt() {
        return maxCreatedAt;
    }

    public SyncQuery setMaxCreatedAt(Instant maxCreatedAt) {
        this.maxCreatedAt = maxCreatedAt;
        return this;
    }

}