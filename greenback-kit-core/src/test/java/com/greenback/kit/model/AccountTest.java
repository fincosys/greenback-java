package com.greenback.kit.model;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.junit.Assert.assertThat;
import org.junit.Test;

public class AccountTest {

    @Test
    public void namePrefersOverlay() {
        final Account account = new Account()
            .setDefaultName("Default")
            .setOverlayName("Overlay");
        assertThat(account.getName(), is("Overlay"));
        account.setOverlayName("");
        assertThat(account.getName(), is("Default"));
    }

    @Test
    public void syncHelpersReadExpandMap() {
        final Sync pending = new Sync();
        pending.setId("p1");
        pending.setCreatedAt(Instant.parse("2020-01-01T00:00:00Z"));
        final Sync last = new Sync();
        last.setId("l1");
        last.setCreatedAt(Instant.parse("2020-01-02T00:00:00Z"));
        final Sync ok = new Sync();
        ok.setId("o1");
        ok.setCreatedAt(Instant.parse("2020-01-03T00:00:00Z"));

        final Map<String, Sync> syncs = new LinkedHashMap<>();
        syncs.put("pending", pending);
        syncs.put("last", last);
        syncs.put("ok", ok);

        final Account account = new Account().setSyncs(syncs);
        assertThat(account.getPendingSync().getId(), is("p1"));
        assertThat(account.getLastSync().getId(), is("l1"));
        assertThat(account.getOkSync().getId(), is("o1"));
        assertThat(account.getPendingSyncCreatedAt(), is(pending.getCreatedAt()));
        assertThat(account.getLastSyncCreatedAt(), is(last.getCreatedAt()));
        assertThat(account.getOkSyncCreatedAt(), is(ok.getCreatedAt()));
    }

    @Test
    public void syncHelpersNullSafe() {
        final Account account = new Account();
        assertThat(account.getPendingSync(), nullValue());
        assertThat(account.getOkSyncCreatedAt(), nullValue());
    }

}
