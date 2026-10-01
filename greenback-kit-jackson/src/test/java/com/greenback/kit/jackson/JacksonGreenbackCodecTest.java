package com.greenback.kit.jackson;

import com.greenback.kit.model.GreenbackException;
import com.greenback.kit.model.ProcessingStatus;
import com.greenback.kit.model.Sync;
import com.greenback.kit.model.SyncType;
import com.greenback.kit.model.TransactionQuery;
import com.greenback.kit.model.TransactionType;
import com.greenback.kit.model.AccountQuery;
import com.greenback.kit.model.AccountType;
import com.greenback.kit.model.AccountState;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.collection.IsMapContaining.hasEntry;
import org.junit.Test;

public class JacksonGreenbackCodecTest {
 
    static private final JacksonGreenbackCodec CODEC = new JacksonGreenbackCodec();
    
    @Test
    public void writeEnum() throws IOException {
        final String json1 = new String(CODEC.writeBytes(TransactionType.SALES_RECEIPT), StandardCharsets.UTF_8);
        
        assertThat(json1, is("\"sales_receipt\""));
        
        
        final Map<TransactionType,String> data = new LinkedHashMap<>();
        data.put(TransactionType.INVOICE, "a");
        data.put(TransactionType.SALES_RECEIPT, "b");
        
        final String json2 = new String(CODEC.writeBytes(data), StandardCharsets.UTF_8);
        
        assertThat(json2, is("{\"invoice\":\"a\",\"sales_receipt\":\"b\"}"));
    }
    
    @Test
    public void toFlattenedMap() throws IOException {
        final TransactionQuery query = new TransactionQuery()
            .setMinTransactedAt(Instant.parse("2022-01-22T01:02:03.456Z"))
            .setMaxTransactedAt(Instant.parse("2022-01-22T01:02:03.000Z"));
        
        final Map<String,Object> flattenedMap = CODEC.toFlattenedMap(query);
        
        assertThat(flattenedMap, hasEntry("min_transacted_at", "2022-01-22T01:02:03.456Z"));
        assertThat(flattenedMap, hasEntry("max_transacted_at", "2022-01-22T01:02:03.000Z"));
        
    }

    @Test
    public void accountQueryToFlattenedMap() throws IOException {
        final AccountQuery query = new AccountQuery()
            .setTypes(AccountType.SHOEBOX, AccountType.MAILBOX)
            .setStates(AccountState.ACTIVE)
            .setConnectIds("c1");

        final Map<String,Object> flattenedMap = CODEC.toFlattenedMap(query);

        assertThat(flattenedMap, hasEntry("types", java.util.Arrays.asList("shoebox", "mailbox")));
        assertThat(flattenedMap, hasEntry("states", java.util.Arrays.asList("active")));
        assertThat(flattenedMap, hasEntry("connect_ids", java.util.Arrays.asList("c1")));
    }

    @Test
    public void readSyncSuccessFixture() throws IOException {
        try (InputStream in = openFixture("fixtures/sync_success.json")) {
            final Sync sync = CODEC.readSync(in);
            assertThat(sync.getId(), is("LowVyqVzPQ"));
            assertThat(sync.getAccountId(), is("exBKAywEad"));
            assertThat(sync.getType(), is(SyncType.DEFAULT));
            assertThat(sync.getStatus(), is(ProcessingStatus.SUCCESS));
            assertThat(sync.getProgress(), is(1.0d));
            assertThat(sync.getSummary(), notNullValue());
            assertThat(sync.getSummary().getTransactions().getCreated(), is(3));
            assertThat(sync.getInput(), nullValue());
        }
    }

    @Test
    public void readSyncWithInputFixture() throws IOException {
        try (InputStream in = openFixture("fixtures/sync_with_input.json")) {
            final Sync sync = CODEC.readSync(in);
            assertThat(sync.getStatus(), is(ProcessingStatus.PROCESSING));
            assertThat(sync.getInput(), notNullValue());
            assertThat(sync.getInput().getTitle(), is("Enter verification code"));
            assertThat(sync.getInput().getFields().get(0).getName(), is("code"));
        }
    }

    @Test(expected = GreenbackException.class)
    public void ensureSuccessThrowsOnError() throws IOException {
        try (InputStream in = openFixture("fixtures/error_unauthorized.json")) {
            CODEC.ensureSuccess(in);
        }
    }

    static private InputStream openFixture(String path) throws IOException {
        final InputStream in = JacksonGreenbackCodecTest.class.getClassLoader().getResourceAsStream(path);
        if (in == null) {
            throw new IOException("Missing fixture: " + path);
        }
        return in;
    }
    
}
