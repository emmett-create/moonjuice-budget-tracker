# Moon Juice Budget Tracker

Cloned from `madegood-budget-tracker` 2026-09-23, per Olivia's Slack ask
("could you make a budget tracker for the moon juice campaign? budget: 75k")
and Emmett's follow-up that it should have Lumanu built in from the start,
same as MadeGood's. Budget set to $75,000.

Everything MadeGood's tracker has is here too: the Needs Review inbox (for
both DocuSign contracts and invoice-sourced entries), Send to Lumanu,
retroactive invoice attach, contract link, calendar/invoice/sent views. Left
out on purpose: the BTS/Pumpkin Spice/Whitelisting tally strip — those were
MadeGood-specific campaign names; add an equivalent for Moon Juice's actual
campaigns later if useful.

## Setup status

Decided 2026-09-23: rather than a new Supabase project, Moon Juice shares
MadeGood's existing one — `moonjuice_budget_entries` lives alongside
`madegood_budget_entries` there. Done as of this decision:

- [x] Table created (`supabase_setup.sql`, run in the shared project's SQL Editor)
- [x] `docs/config.js` pointed at the shared project
- [x] `"moonjuice"` added to `budget-tracker-lumanu-bridge/config.py`'s
      `CLIENTS` dict — reuses MadeGood's `invoices` Storage bucket (paths are
      namespaced by client, so no collision) and its existing
      `MADEGOOD_SUPABASE_SERVICE_KEY` Render secret (that key is project-wide,
      not per-table, so no new secret was needed)

## Still needed

1. **GL Account** — starts unset (`None`), same situation MadeGood is in.
   `/api/lumanu/send` will refuse to send until it's filled in.
2. **Push this repo to GitHub**, enable GitHub Pages serving from `/docs`,
   matching every other tracker (`emmett-create.github.io/moonjuice-budget-tracker/`).
3. **Set up the invoicing Zap** for Moon Juice — duplicate the MadeGood zap,
   change the Subject filter to `Moon Juice`, same as any other new client
   onboarding onto this pipeline.

None of these block basic manual use (adding entries by hand, tracking the
$75k budget) — only the Lumanu-integrated parts need them.
