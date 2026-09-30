package com.greenback.kit.model;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Request body for POST /v2/syncs/{sync_id}/inputs (e.g. 2FA answers).
 */
public class SyncInputRequest {

    private Map<String, String> parameters;

    public Map<String, String> getParameters() {
        return parameters;
    }

    public SyncInputRequest setParameters(Map<String, String> parameters) {
        this.parameters = parameters;
        return this;
    }

    public SyncInputRequest addParameter(String name, String value) {
        if (this.parameters == null) {
            this.parameters = new LinkedHashMap<>();
        }
        this.parameters.put(name, value);
        return this;
    }

}