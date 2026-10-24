/*
# Greenback core: contacts, connects, accounts, syncs

Mirrors the Greenback Kit data model (com.greenback.kit.model) so the platform's
connections, linked accounts and sync jobs can be persisted.

1. New Tables
- `contacts` - vendors / merchants (id, domain, name, email, logo_url)
- `connects` - catalog of integrations a user can link (Amazon, Gmail, QuickBooks...)
  - label (unique slug), type, name, state, tags, logo_url, auth_strategy, contact_id
- `accounts` - a linked account created from a connect
  - connect_id, reference_id, type, state, connection_state, consecutive_errors,
    default_name, overlay_name
- `syncs` - a data-acquisition run for an account
  - account_id, reference_id, type, triggered_by, message, progress (0..1), status,
    error/input/request/summary (jsonb snapshots of the SDK objects)

2. Helpers
- `set_updated_at()` trigger function keeps `updated_at` current on every table.

3. Security
- RLS enabled on all tables.
- No sign-in exists yet, so CRUD is granted to `anon` + `authenticated` with
  intentionally shared (USING true) policies; `service_role` granted for server code.
- `set_updated_at()` is not callable as an RPC (EXECUTE revoked from PUBLIC/anon).

4. Notes
1. Enum-like columns use CHECK constraints matching the Java enums exactly.
2. When multi-user sign-in is added, owner columns + owner-scoped policies should replace the shared policies.
*/

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;

CREATE TABLE IF NOT EXISTS contacts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain text,
  name text NOT NULL,
  email text,
  logo_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS contacts_domain_key ON contacts (lower(domain)) WHERE domain IS NOT NULL;

CREATE TABLE IF NOT EXISTS connects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL UNIQUE,
  type text NOT NULL CHECK (type IN ('MERCHANT','MAILBOX','ACCOUNTING','SHOEBOX')),
  name text NOT NULL,
  state text NOT NULL DEFAULT 'ACTIVE' CHECK (state IN ('ACTIVE','BETA','UPCOMING')),
  tags text[] NOT NULL DEFAULT '{}',
  logo_url text,
  auth_strategy text NOT NULL DEFAULT 'DEFAULT' CHECK (auth_strategy IN ('DEFAULT','REDIRECT','NONE')),
  contact_id uuid REFERENCES contacts(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS connects_type_idx ON connects (type);
CREATE INDEX IF NOT EXISTS connects_contact_id_idx ON connects (contact_id);

CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  connect_id uuid NOT NULL REFERENCES connects(id) ON DELETE RESTRICT,
  reference_id text,
  type text NOT NULL CHECK (type IN ('MERCHANT','MAILBOX','ACCOUNTING','SHOEBOX')),
  state text NOT NULL DEFAULT 'ACTIVE' CHECK (state IN ('ACTIVE','SUSPENDED','DISCONNECTED','DELETED')),
  connection_state text NOT NULL DEFAULT 'PENDING' CHECK (connection_state IN ('OK','PENDING','FAILED','AUTH_FAILURE')),
  consecutive_errors integer NOT NULL DEFAULT 0 CHECK (consecutive_errors >= 0),
  default_name text,
  overlay_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS accounts_connect_id_idx ON accounts (connect_id);
CREATE INDEX IF NOT EXISTS accounts_state_idx ON accounts (state);

CREATE TABLE IF NOT EXISTS syncs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  reference_id text,
  type text NOT NULL DEFAULT 'DEFAULT' CHECK (type IN ('DEFAULT','INDEX','REVIEW','VOLUME_QUOTE')),
  triggered_by text CHECK (triggered_by IN ('WEB','AUTO','API','SUPPORT','SMTP','DATA_PENDING')),
  message text,
  progress numeric(5,4) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 1),
  status text NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','PROCESSING','SUCCESS','ERROR')),
  error jsonb,
  input jsonb,
  request jsonb,
  summary jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS syncs_account_id_created_idx ON syncs (account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS syncs_status_idx ON syncs (status);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['contacts','connects','accounts','syncs'] LOOP
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