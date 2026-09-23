-- Run this in Supabase → SQL Editor (in a brand-new Supabase project for Moon Juice)
--
-- This is a consolidated version of everything madegood-budget-tracker's own
-- supabase_setup.sql built up incrementally over time (DocuSign inbox, Lumanu
-- integration, retroactive invoice attach, contract link) — Moon Juice starts
-- with Lumanu already built in from day one, so there's no migration history
-- to replay, just the final schema.
--
-- One thing NOT included here on purpose: this account is created AFTER
-- Supabase's 2026-10-30 policy change (see conversation 2026-09-23) — any
-- new table created after that date needs explicit GRANT statements or the
-- Data API can't reach it. If this project is created after Oct 30, add:
--
--   grant select on public.moonjuice_budget_entries to anon;
--   grant select, insert, update, delete on public.moonjuice_budget_entries to authenticated;
--   grant select, insert, update, delete on public.moonjuice_budget_entries to service_role;

CREATE TABLE moonjuice_budget_entries (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date            date NOT NULL,
  category        text CHECK (category IN ('a8_paid', 'moonjuice_paid', 'shipping')),
  entry_type      text NOT NULL DEFAULT 'actual' CHECK (entry_type IN ('actual', 'planned')),
  creator_handle  text,
  description     text,
  amount          numeric(12, 2) NOT NULL,
  notes           text,
  status          text NOT NULL DEFAULT 'confirmed',        -- 'pending' = sitting in the Needs Review inbox
  source          text NOT NULL DEFAULT 'manual',            -- 'invoice_email' | 'manual' | (docusign zap, if added later)
  ready_to_invoice boolean NOT NULL DEFAULT false,
  billing_id      text,                                      -- Lumanu ID or billing email
  due_date        date,
  po_number       text,
  lumanu_status   text NOT NULL DEFAULT 'not_sent'
    CHECK (lumanu_status IN ('not_sent','needs_approval','approved','pending','issued','canceled')),
  lumanu_payable_id text,                                     -- set once actually sent to Lumanu; prevents double-sends
  invoice_path    text,                                       -- path in the private "invoices" Storage bucket
  contract_link   text,                                       -- plain link to the signed contract (DocuSign or any URL)
  planned_amount  numeric(12, 2),                              -- unused going forward (Planned was retired 2026-09-22), kept for schema parity
  created_at      timestamptz DEFAULT now()
);

-- Allow public read/write (no login required — internal tool, same as every other tracker)
ALTER TABLE moonjuice_budget_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read"   ON moonjuice_budget_entries FOR SELECT USING (true);
CREATE POLICY "Public insert" ON moonjuice_budget_entries FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON moonjuice_budget_entries FOR UPDATE USING (true);
CREATE POLICY "Public delete" ON moonjuice_budget_entries FOR DELETE USING (true);

-- Private bucket for attached invoice PDFs — same pattern as every other
-- tracker (never a public URL; the bridge hands back a short-lived signed
-- URL to view one). Create this in Supabase → Storage → New bucket, name it
-- exactly "invoices", and leave "Public bucket" UNCHECKED.
