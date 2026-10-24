/*
# Greenback documents: messages, visions, transactions, line items, payments, attachments

Stores the "high-def itemized" financial data the Greenback Kit produces from
emails (Mailbox API), photos/documents (Vision API) and connected merchants.

1. New Tables
- `messages` - RFC822 emails converted by the Mailbox API
  - account_id, reference_id, status, size, subject, snippet, from_address,
    reply_to/to_addresses/cc/bcc (jsonb arrays of {name,email}), quoted, full_text, posted_at
- `visions` - Vision API extraction runs (name, status, annotations, transaction_matcher)
- `transactions` - itemized financial transactions
  - reference_id, account_id, contact_id, message_id, vision_id (source links)
  - archetype, type, currency_code, alt/display reference ids
  - status_state / status_message / status_updated_at (TransactionStatus)
  - billing/shipping/store_address (jsonb PostalAddress)
  - totals: total_sub, total_fee, total_discount, total_ship, total_tip, total_tax,
    total_other, total_grand plus total_items (jsonb TotalsItem list)
  - exchange_rates, settlements, meta, attributes (jsonb), flags (text[] DocumentFlag)
  - transacted_at, due_at
- `transaction_items` - line items (position, grn, alt_grns, name, description,
  quantity, unit_price, amount, tax_grn)
- `transaction_payments` - payments and deposits (kind = PAYMENT | DEPOSIT, method,
  sub_method, network, domain, ends_with, amount, paid_at, reference_id, name, memo)
- `attachments` - files belonging to exactly one transaction, message or vision
  (name, media_type, size, md5, why, reference_id, storage_path)

2. Security
- RLS enabled on all tables; CRUD granted to anon + authenticated (+ service_role)
  with intentionally shared policies, since the project has no sign-in yet.

3. Notes
1. Deleting a transaction removes its items, payments and attachments (cascade).
2. Deleting a message/vision keeps derived transactions but clears the link.
3. Enum CHECK constraints match the Java enums exactly.
*/

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid REFERENCES accounts(id) ON DELETE SET NULL,
  reference_id text,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','SUCCESS','ERROR')),
  size integer CHECK (size >= 0),
  subject text,
  snippet text,
  from_address jsonb,
  reply_to jsonb NOT NULL DEFAULT '[]',
  to_addresses jsonb NOT NULL DEFAULT '[]',
  cc jsonb NOT NULL DEFAULT '[]',
  bcc jsonb NOT NULL DEFAULT '[]',
  quoted jsonb NOT NULL DEFAULT '[]',
  full_text text,
  posted_at timestamptz,
  flags text[] NOT NULL DEFAULT '{}',
  attributes jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS messages_account_id_idx ON messages (account_id);
CREATE INDEX IF NOT EXISTS messages_posted_at_idx ON messages (posted_at DESC);

CREATE TABLE IF NOT EXISTS visions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id text,
  name text,
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','SUCCESS','ERROR')),
  annotations jsonb,
  transaction_matcher jsonb,
  flags text[] NOT NULL DEFAULT '{}',
  attributes jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS visions_status_idx ON visions (status);

CREATE TABLE IF NOT EXISTS transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference_id text,
  account_id uuid REFERENCES accounts(id) ON DELETE SET NULL,
  contact_id uuid REFERENCES contacts(id) ON DELETE SET NULL,
  message_id uuid REFERENCES messages(id) ON DELETE SET NULL,
  vision_id uuid REFERENCES visions(id) ON DELETE SET NULL,
  archetype text NOT NULL DEFAULT 'CORE' CHECK (archetype IN ('CORE','ROLLUP')),
  type text NOT NULL CHECK (type IN ('SALES_RECEIPT','INVOICE','REFUND','PURCHASE','BILL','REIMBURSEMENT')),
  currency_code char(3) NOT NULL DEFAULT 'USD' CHECK (currency_code ~ '^[A-Z]{3}$'),
  alt_reference_id text,
  display_reference_id text,
  status_state text CHECK (status_state IN ('OPEN','PERIOD_OPEN','UNPAID','PARTIALLY_PAID','PAID','VOIDED')),
  status_message text,
  status_updated_at timestamptz,
  billing_address jsonb,
  shipping_address jsonb,
  store_address jsonb,
  total_sub numeric(14,4),
  total_fee numeric(14,4),
  total_discount numeric(14,4),
  total_ship numeric(14,4),
  total_tip numeric(14,4),
  total_tax numeric(14,4),
  total_other numeric(14,4),
  total_grand numeric(14,4),
  total_items jsonb NOT NULL DEFAULT '[]',
  exchange_rates jsonb NOT NULL DEFAULT '[]',
  settlements jsonb NOT NULL DEFAULT '[]',
  meta jsonb,
  flags text[] NOT NULL DEFAULT '{}',
  attributes jsonb NOT NULL DEFAULT '{}',
  transacted_at timestamptz,
  due_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS transactions_account_transacted_idx ON transactions (account_id, transacted_at DESC);
CREATE INDEX IF NOT EXISTS transactions_contact_id_idx ON transactions (contact_id);
CREATE INDEX IF NOT EXISTS transactions_message_id_idx ON transactions (message_id);
CREATE INDEX IF NOT EXISTS transactions_vision_id_idx ON transactions (vision_id);
CREATE INDEX IF NOT EXISTS transactions_type_idx ON transactions (type);
CREATE INDEX IF NOT EXISTS transactions_flags_idx ON transactions USING gin (flags);

CREATE TABLE IF NOT EXISTS transaction_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  position integer NOT NULL DEFAULT 0,
  grn text,
  alt_grns text[] NOT NULL DEFAULT '{}',
  name text NOT NULL,
  description text,
  quantity numeric(14,4),
  unit_price numeric(14,4),
  amount numeric(14,4),
  tax_grn text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS transaction_items_transaction_idx ON transaction_items (transaction_id, position);

CREATE TABLE IF NOT EXISTS transaction_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  kind text NOT NULL DEFAULT 'PAYMENT' CHECK (kind IN ('PAYMENT','DEPOSIT')),
  rel_id text,
  method text CHECK (method IN ('CREDIT_CARD','DEBIT_CARD','REWARD','PAYPAL','GOOGLE_WALLET','GIFT_CARD','MONEY_TRANSFER','CASH','STORE_CREDIT','CHECK','APPLE_PAY','MONEY_ORDER','BANK_ACCOUNT','SELLER_ACCOUNT')),
  sub_method text,
  network text CHECK (network IN ('VISA','MASTERCARD','AMEX','DISCOVER','SEPA')),
  domain text,
  ends_with text CHECK (ends_with ~ '^[0-9A-Za-z]{1,8}$'),
  amount numeric(14,4),
  paid_at timestamptz,
  reference_id text,
  name text,
  memo text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS transaction_payments_transaction_idx ON transaction_payments (transaction_id, kind);

CREATE TABLE IF NOT EXISTS attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id uuid REFERENCES transactions(id) ON DELETE CASCADE,
  message_id uuid REFERENCES messages(id) ON DELETE CASCADE,
  vision_id uuid REFERENCES visions(id) ON DELETE CASCADE,
  rel_id text,
  reference_id text,
  name text,
  media_type text,
  size integer CHECK (size >= 0),
  md5 text CHECK (md5 ~ '^[0-9a-f]{32}$'),
  why text CHECK (why IN ('ORIGINAL')),
  storage_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT attachments_single_owner CHECK (num_nonnulls(transaction_id, message_id, vision_id) = 1)
);
CREATE INDEX IF NOT EXISTS attachments_transaction_idx ON attachments (transaction_id);
CREATE INDEX IF NOT EXISTS attachments_message_idx ON attachments (message_id);
CREATE INDEX IF NOT EXISTS attachments_vision_idx ON attachments (vision_id);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['messages','visions','transactions','transaction_items','transaction_payments','attachments'] LOOP
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