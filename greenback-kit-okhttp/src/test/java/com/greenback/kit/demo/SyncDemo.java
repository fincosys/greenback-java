package com.greenback.kit.demo;

import com.greenback.kit.client.GreenbackClient;
import com.greenback.kit.client.GreenbackConstants;
import com.greenback.kit.jackson.JacksonGreenbackCodec;
import com.greenback.kit.model.Account;
import com.greenback.kit.model.Paginated;
import com.greenback.kit.model.Sync;
import com.greenback.kit.model.SyncRequest;
import com.greenback.kit.model.Transaction;
import com.greenback.kit.model.TransactionQuery;
import com.greenback.kit.okhttp.OkHttpGreenbackClient;
import com.greenback.kit.okhttp.OkHttpHelper;
import com.greenback.kit.util.ProcessingPoller;
import static java.util.Arrays.asList;
import static java.util.Optional.ofNullable;
import java.util.Properties;
import okhttp3.OkHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Demo: load an account (with syncs expand), trigger a sync, poll until terminal,
 * then list recent transactions for that account.
 *
 * Configure ~/.greenback.conf with access_token and optional base_url / account_id.
 */
public class SyncDemo {
    static private final Logger log = LoggerFactory.getLogger(SyncDemo.class);

    static public final void main(String[] args) throws Exception {
        final Properties config = DemoHelper.userProperties();
        final OkHttpClient httpClient = DemoHelper.httpClient(log);
        final String baseUrl = ofNullable(config.getProperty("base_url"))
            .orElse(GreenbackConstants.ENDPOINT_PRODUCTION);
        final String accessToken = ofNullable(config.getProperty("access_token"))
            .orElse("access-token-here");
        final String accountId = ofNullable(config.getProperty("account_id"))
            .orElse("account-id-here");

        try {
            final GreenbackClient client = new OkHttpGreenbackClient(
                httpClient,
                baseUrl,
                new JacksonGreenbackCodec(),
                accessToken);

            Account account = client.getAccountById(accountId, asList("connect", "syncs"));
            log.debug("Account: id={}, name={}, pendingSync={}, lastSync={}",
                account != null ? account.getId() : null,
                account != null ? account.getName() : null,
                account != null && account.getPendingSync() != null ? account.getPendingSync().getId() : null,
                account != null && account.getLastSync() != null ? account.getLastSync().getId() : null);

            Sync sync = client.createAccountSync(accountId, new SyncRequest()
                .setLimit(25));

            log.debug("Sync created: id={}, status={}, progress={}, message={}",
                sync.getId(), sync.getStatus(), sync.getProgress(), sync.getMessage());

            final String syncId = sync.getId();
            sync = ProcessingPoller.awaitTerminal(
                () -> client.getSyncById(syncId),
                Sync::getStatus,
                1000L,
                120);

            log.debug("Sync finished: id={}, status={}, progress={}, message={}, hasInput={}",
                sync.getId(),
                sync.getStatus(),
                sync.getProgress(),
                sync.getMessage(),
                sync.getInput() != null);

            if (sync.getInput() != null) {
                log.warn("Sync is waiting for user input (e.g. 2FA). Use createSyncInput to continue.");
            }

            final Paginated<Transaction> transactions = client.getTransactions(new TransactionQuery()
                .setAccountIds(asList(accountId))
                .setLimit(10));

            for (Transaction transaction : transactions) {
                log.debug("Transaction: id={}, type={}, ref={}",
                    transaction.getId(), transaction.getType(), transaction.getReferenceId());
            }
        }
        catch (Exception e) {
            log.error("Uh oh!", e);
        }
        finally {
            OkHttpHelper.shutdown(httpClient);
        }
    }

}
