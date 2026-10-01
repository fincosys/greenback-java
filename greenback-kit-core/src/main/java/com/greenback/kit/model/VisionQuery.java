package com.greenback.kit.model;

import java.time.Instant;

/**
 * Query parameters for listing visions when the deployment supports it.
 */
public class VisionQuery extends Query<VisionQuery> {

    protected Iterable<ProcessingStatus> statuses;
    protected Instant minCreatedAt;
    protected Instant maxCreatedAt;

    public Iterable<ProcessingStatus> getStatuses() {
        return statuses;
    }

    public VisionQuery setStatuses(Iterable<ProcessingStatus> statuses) {
        this.statuses = statuses;
        return this;
    }

    public Instant getMinCreatedAt() {
        return minCreatedAt;
    }

    public VisionQuery setMinCreatedAt(Instant minCreatedAt) {
        this.minCreatedAt = minCreatedAt;
        return this;
    }

    public Instant getMaxCreatedAt() {
        return maxCreatedAt;
    }

    public VisionQuery setMaxCreatedAt(Instant maxCreatedAt) {
        this.maxCreatedAt = maxCreatedAt;
        return this;
    }

}