package com.greenback.kit.model;

import java.time.Instant;

import static com.greenback.kit.util.Utils.toIterable;

public class AccountQuery extends Query<AccountQuery> {

    protected Iterable<AccountType> types;
    protected Iterable<AccountState> states;
    protected Iterable<AccountConnectionState> connectionStates;
    protected Iterable<String> connectIds;
    protected Iterable<String> userIds;
    protected Instant minCreatedAt;
    protected Instant maxCreatedAt;
    protected Instant minUpdatedAt;
    protected Instant maxUpdatedAt;

    public Iterable<AccountType> getTypes() {
        return types;
    }

    public AccountQuery setTypes(Iterable<AccountType> types) {
        this.types = types;
        return this;
    }

    public AccountQuery setTypes(AccountType... types) {
        return this.setTypes(toIterable(types));
    }

    public Iterable<AccountState> getStates() {
        return states;
    }

    public AccountQuery setStates(Iterable<AccountState> states) {
        this.states = states;
        return this;
    }

    public AccountQuery setStates(AccountState... states) {
        return this.setStates(toIterable(states));
    }

    public Iterable<AccountConnectionState> getConnectionStates() {
        return connectionStates;
    }

    public AccountQuery setConnectionStates(Iterable<AccountConnectionState> connectionStates) {
        this.connectionStates = connectionStates;
        return this;
    }

    public AccountQuery setConnectionStates(AccountConnectionState... connectionStates) {
        return this.setConnectionStates(toIterable(connectionStates));
    }

    public Iterable<String> getConnectIds() {
        return connectIds;
    }

    public AccountQuery setConnectIds(Iterable<String> connectIds) {
        this.connectIds = connectIds;
        return this;
    }

    public AccountQuery setConnectIds(String... connectIds) {
        return this.setConnectIds(toIterable(connectIds));
    }

    public Iterable<String> getUserIds() {
        return userIds;
    }

    public AccountQuery setUserIds(Iterable<String> userIds) {
        this.userIds = userIds;
        return this;
    }

    public AccountQuery setUserIds(String... userIds) {
        return this.setUserIds(toIterable(userIds));
    }

    public Instant getMinCreatedAt() {
        return minCreatedAt;
    }

    public AccountQuery setMinCreatedAt(Instant minCreatedAt) {
        this.minCreatedAt = minCreatedAt;
        return this;
    }

    public Instant getMaxCreatedAt() {
        return maxCreatedAt;
    }

    public AccountQuery setMaxCreatedAt(Instant maxCreatedAt) {
        this.maxCreatedAt = maxCreatedAt;
        return this;
    }

    public Instant getMinUpdatedAt() {
        return minUpdatedAt;
    }

    public AccountQuery setMinUpdatedAt(Instant minUpdatedAt) {
        this.minUpdatedAt = minUpdatedAt;
        return this;
    }

    public Instant getMaxUpdatedAt() {
        return maxUpdatedAt;
    }

    public AccountQuery setMaxUpdatedAt(Instant maxUpdatedAt) {
        this.maxUpdatedAt = maxUpdatedAt;
        return this;
    }

}
