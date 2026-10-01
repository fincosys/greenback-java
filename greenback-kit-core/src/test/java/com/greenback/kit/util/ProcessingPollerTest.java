package com.greenback.kit.util;

import com.greenback.kit.model.ProcessingStatus;
import java.util.concurrent.atomic.AtomicInteger;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;
import org.junit.Test;

public class ProcessingPollerTest {

    @Test
    public void awaitsTerminalStatus() throws Exception {
        final AtomicInteger calls = new AtomicInteger();
        final String result = ProcessingPoller.awaitTerminal(
            () -> {
                final int n = calls.incrementAndGet();
                return n < 3 ? "pending" : "done";
            },
            v -> "done".equals(v) ? ProcessingStatus.SUCCESS : ProcessingStatus.PROCESSING,
            1L,
            10);
        assertThat(result, is("done"));
        assertThat(calls.get(), is(3));
    }

    @Test
    public void returnsLastWhenNeverTerminal() throws Exception {
        final AtomicInteger calls = new AtomicInteger();
        final String result = ProcessingPoller.awaitTerminal(
            () -> "still-" + calls.incrementAndGet(),
            v -> ProcessingStatus.PENDING,
            0L,
            3);
        assertThat(result, is("still-3"));
        assertThat(calls.get(), is(3));
    }

}
