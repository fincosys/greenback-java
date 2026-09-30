package com.greenback.kit.model;

import java.util.Map;

public class Account extends GreenbackObject {
 
    private String userId;
    private String connectId;
    private String referenceId;
    private AccountType type;
    private AccountState state;
    private AccountConnectionState connectionState;
    private Integer consecutiveErrors;
    private String defaultName;
    private String overlayName;
    
    // expandable
    
    private Connect connect;
    private Map<String,Sync> syncs;

    public String getUserId() {
        return userId;
    }

    public Account setUserId(String userId) {
        this.userId = userId;
        return this;
    }

    public String getConnectId() {
        return connectId;
    }

    public Account setConnectId(String connectId) {
        this.connectId = connectId;
        return this;
    }

    public String getReferenceId() {
        return referenceId;
    }

    public Account setReferenceId(String referenceId) {
        this.referenceId = referenceId;
        return this;
    }
    
    public AccountType getType() {
        return type;
    }

    public Account setType(AccountType type) {
        this.type = type;
        return this;
    }
    
    public String getDefaultName() {
        return defaultName;
    }

    public Account setDefaultName(String defaultName) {
        this.defaultName = defaultName;
        return this;
    }

    public String getOverlayName() {
        return overlayName;
    }

    public Account setOverlayName(String overlayName) {
        this.overlayName = overlayName;
        return this;
    }

    public AccountState getState() {
        return state;
    }

    public Account setState(AccountState state) {
        this.state = state;
        return this;
    }

    public AccountConnectionState getConnectionState() {
        return connectionState;
    }

    public Account setConnectionState(AccountConnectionState connectionState) {
        this.connectionState = connectionState;
        return this;
    }

    public Integer getConsecutiveErrors() {
        return consecutiveErrors;
    }

    public Account setConsecutiveErrors(Integer consecutiveErrors) {
        this.consecutiveErrors = consecutiveErrors;
        return this;
    }

    // helpers

    /**
     * Display name preferring an overlay name when present.
     */
    public String getName() {
        if (this.overlayName != null && !this.overlayName.isEmpty()) {
            return this.overlayName;
        }
        return this.defaultName;
    }

    public Sync getPendingSync() {
        return this.syncNamed("pending");
    }

    public Sync getLastSync() {
        return this.syncNamed("last");
    }

    public Sync getOkSync() {
        return this.syncNamed("ok");
    }

    public java.time.Instant getOkSyncCreatedAt() {
        final Sync sync = this.getOkSync();
        return sync != null ? sync.getCreatedAt() : null;
    }

    public java.time.Instant getPendingSyncCreatedAt() {
        final Sync sync = this.getPendingSync();
        return sync != null ? sync.getCreatedAt() : null;
    }

    public java.time.Instant getLastSyncCreatedAt() {
        final Sync sync = this.getLastSync();
        return sync != null ? sync.getCreatedAt() : null;
    }

    private Sync syncNamed(String key) {
        if (this.syncs == null || key == null) {
            return null;
        }
        return this.syncs.get(key);
    }

    // expandable

    public Connect getConnect() {
        return connect;
    }

    public Account setConnect(Connect connect) {
        this.connect = connect;
        return this;
    }
    
    public Map<String,Sync> getSyncs() {
        return syncs;
    }

    public Account setSyncs(Map<String,Sync> syncs) {
        this.syncs = syncs;
        return this;
    }

    @Override
    public String toString() {
        return "Account{" +
            "userId='" + userId + '\'' +
            ", connectId='" + connectId + '\'' +
            ", referenceId='" + referenceId + '\'' +
            ", type=" + type +
            ", state=" + state +
            ", connectionState=" + connectionState +
            ", consecutiveErrors=" + consecutiveErrors +
            ", defaultName='" + defaultName + '\'' +
            ", overlayName='" + overlayName + '\'' +
            ", connect=" + connect +
            ", syncs=" + syncs +
            ", id='" + id + '\'' +
            ", createdAt=" + createdAt +
            ", updatedAt=" + updatedAt +
            '}';
    }
}