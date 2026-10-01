package com.greenback.kit.util;

import com.greenback.kit.model.ProcessingStatus;
import java.io.IOException;
import java.util.Objects;
import java.util.function.Function;

/**
 * Small helper to poll resources that expose a {@link ProcessingStatus}
 * until they reach a terminal state (success or error).
 */
public final class ProcessingPoller {

    private ProcessingPoller() {
    }

    @FunctionalInterface
    public interface IoSupplier<T> {
        T get() throws IOException;
    }

    /**
     * Polls {@code loader} until the extracted status is terminal or attempts are exhausted.
     *
     * @param loader loads the latest resource snapshot
     * @param statusExtractor reads the processing status from the snapshot
     * @param pollIntervalMillis sleep between attempts (clamped to &gt;= 0)
     * @param maxAttempts maximum load attempts (must be &gt;= 1)
     * @return the last loaded snapshot (terminal or final attempt)
     */
    static public <T> T awaitTerminal(
            IoSupplier<T> loader,
            Function<T, ProcessingStatus> statusExtractor,
            long pollIntervalMillis,
            int maxAttempts) throws IOException, InterruptedException {

        Objects.requireNonNull(loader, "loader was null");
        Objects.requireNonNull(statusExtractor, "statusExtractor was null");
        if (maxAttempts < 1) {
            throw new IllegalArgumentException("maxAttempts must be >= 1");
        }

        final long sleepMs = Math.max(0L, pollIntervalMillis);
        T current = null;

        for (int attempt = 0; attempt < maxAttempts; attempt++) {
            current = loader.get();
            final ProcessingStatus status = statusExtractor.apply(current);
            if (status != null && status.isTerminal()) {
                return current;
            }
            if (attempt + 1 < maxAttempts && sleepMs > 0L) {
                Thread.sleep(sleepMs);
            }
        }

        return current;
    }

}