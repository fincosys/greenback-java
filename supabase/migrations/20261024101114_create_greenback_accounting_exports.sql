/*
# Greenback accounting exports: transaction_exports, auto_exports, export_runs

Tracks pushing transactions into accounting systems (QuickBooks, Xero, ...).

1. New Tables
- `transaction_exports` - one export of a transaction to an accounting account
  - transaction_id, account_id, triggered_by, mode (LEGACY|PAYMENT),
    accounting_method (CASH|ACCRUAL|PSEUDO_ACCRUAL), steps (jsonb)
- `auto_exports` - recurring export schedules
  - accounting_account_id, parameters (jsonb), frequency (DAILY|WEEKLY),
    state (ACTIVE|ARCHIVED|DELETED), last_run_at
- `auto_export_accounts` - source accounts included in an auto export
  (replaces the SDK's accountIds list with a proper relation)
- `export_runs` - a single execution of an auto export
  - auto_export_id, reference_id, status, progress, message, parameters, results,
    triggered_by, killed_at, completed_at

2. Security
- RLS enabled on all tables; CRUD granted to anon + authenticated (+ service_role)
  with intentionally shared policies, since the project has no sign-in yet.

3. Notes
1. Deleting a transaction removes its export records.
2. Accounting accounts referenced by an auto export cannot be deleted while in use.
*/

CREATE TABLE IF NOT EXISTS transaction_exports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  triggered_by text CHECK (triggered_by IN ('WEB','AUTO','API','SUPPORT','SMTP','DATA_PENDING')),
  mode text NOT NULL DEFAULT 'PAYMENT' CHECK (mode IN ('LEGACY','PAYMENT')),
  accounting_method text NOT NULL DEFAULT 'ACCRUAL' CHECK (accounting_method IN ('CASH','ACCRUAL','PSEUDO_ACCRUAL')),
  steps jsonb NOT NULL DEFAULT '[]',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS transaction_exports_transaction_idx ON transaction_exports (transaction_id);
CREATE INDEX IF NOT EXISTS transaction_exports_account_idx ON transaction_exports (account_id);

CREATE TABLE IF NOT EXISTS auto_exports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  accounting_account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  parameters jsonb NOT NULL DEFAULT '{}',
  frequency text NOT NULL DEFAULT 'DAILY' CHECK (frequency IN ('DAILY','WEEKLY')),
  state text NOT NULL DEFAULT 'ACTIVE' CHECK (state IN ('ACTIVE','ARCHIVED','DELETED')),
  last_run_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS auto_exports_accounting_account_idx ON auto_exports (accounting_account_id);
CREATE INDEX IF NOT EXISTS auto_exports_state_idx ON auto_exports (state);

CREATE TABLE IF NOT EXISTS auto_export_accounts (
  auto_export_id uuid NOT NULL REFERENCES auto_exports(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (auto_export_id, account_id)
);
CREATE INDEX IF NOT EXISTS auto_export_accounts_account_idx ON auto_export_accounts (account_id);

CREATE TABLE IF NOT EXISTS export_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auto_export_id uuid NOT NULL REFERENCES auto_exports(id) ON DELETE CASCADE,
  reference_id text,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','SUCCESS','ERROR')),
  progress numeric(5,4) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  message text,
  parameters jsonb NOT NULL DEFAULT '{}',
  results jsonb,
  triggered_by text CHECK (triggered_by IN ('WEB','AUTO','API','SUPPORT','SMTP','DATA_PENDING')),
  killed_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS export_runs_auto_export_created_idx ON export_runs (auto_export_id, created_at DESC);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['transaction_exports','auto_exports','auto_export_accounts','export_runs'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO anon, authenticated, service_role', t);
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I', t || '_set_updated_at', t);
    EXECUTE format('CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()', t || '_set_updated_at', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'shared_select_' || t, t);
    EXECUTE format('CREATE POLICY %I ON %I FOR SELECT TO anon, authenticated USING (true)', 'shared_select_' || t, t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'shared_insert_' || t, t);
    EXECUTE format('CREATE POLICY %I ON %I FOR INSERT TO anon, authenticated WITH CHECK (true)', 'shared_insert_' || t, t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'shared_update_' || t, t);
    EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true)', 'shared_update_' || t, t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 'shared_delete_' || t, t);
    EXECUTE format('CREATE POLICY %I ON %I FOR DELETE TO anon, authenticated USING (true)', 'shared_delete_' || t, t);
  END LOOP;
END $$;