# Project Charter — BrewDay Log Annotator

PMBOK Initiating artifact. Authorized by the customer (Alex Keller,
2026-04-19, recorded in `CUSTOMER_NOTES.md`). Amend via a row in
`docs/pm/CHANGES.md`.

## 1. Purpose and justification

A solo craft brewer (~5 BBL) needs a durable, legible record of each
brew day: timestamps for process events (grain-in, strike, mash-in,
sparge, boil start, hop additions, whirlpool, knockout, pitch,
crash, transfer), specific-gravity readings, and free-form notes
(aroma, issues). Today the record is hand-written and gets wet, torn,
or lost. This project produces a single-user web app the brewer runs
in the brewhouse, tapping on a tablet with wet hands, and exports a
PDF for the brewing logbook. Without it, the brewer risks non-
compliance with their own process-discipline standards and loses
month-over-month brew-to-brew comparability.

## 2. Measurable objectives and success criteria

| ID | Objective | Success criterion | Verified by |
|---|---|---|---|
| O-1 | Record a complete brew day end-to-end | Brewer walks one real brew day from grain-in through transfer with ≥ 15 preset events logged; no data loss on browser refresh | `qa-engineer` — on-site run-through |
| O-2 | Tablet-usable with wet hands | All tap targets ≥ 48×48 px; no hover-only interactions; contrast ≥ WCAG 2.2 AA | `qa-engineer` against WCAG 2.2 |
| O-3 | PDF export | Completed brew day renders to a paginated PDF with all events, readings, and notes in chronological order | `qa-engineer` — diff against a hand-kept logbook page |
| O-4 | Local-only, no internet dependency | Entire app + DB runs on the brewhouse mini-PC; works with WAN disconnected | `sre` — test with LAN up, WAN down |

## 3. High-level requirements

One-user web app: brewer starts a brew day, adds timed events from a
preset list, attaches notes and SG readings, exports to PDF. Python
FastAPI + HTMX + SQLite on a brewhouse mini-PC; tablet is just a
Chromium browser on the LAN. Detailed requirements in
`docs/requirements.md` (from `docs/templates/requirements-template.md`).

## 4. High-level risks

Top 5 from `docs/pm/RISKS.md`:

1. Wet-hand UX not actually usable with real wet hands (usability gap).
2. Brewhouse Wi-Fi drops mid-day, losing in-flight state (durability gap).
3. PDF export fails to match the layout the brewer's regulator later
   wants (regulatory deferral).
4. Maintenance burden for the brewer post-handoff (stack fit gap).
5. SQLite file corruption on abrupt power loss in the brewhouse.

## 5. Summary milestones

| Milestone | Target date | Exit criterion |
|---|---|---|
| M-1 — Skeleton | 2026-05-10 | FastAPI + HTMX + SQLite scaffold; one event type writable and readable |
| M-2 — Full event set | 2026-05-24 | All preset events (≥ 15) entered, timestamped, persisted |
| M-3 — PDF export + tablet UX | 2026-06-07 | O-1, O-2, O-3 all met |
| M-4 — Offline / durability | 2026-06-21 | O-4 met; SQLite journaling + WAN-down test passes |

## 6. Summary budget

Order-of-magnitude: ~40 person-hours through M-3; ~20 hours M-4.
Basis: bottom-up by milestone. Detailed baseline in `docs/pm/COST.md`.

## 7. Stakeholders

Customer: Alex Keller (brewer). No other stakeholders for Milestone 1.
A future food-safety / licensing reviewer is a plausible stakeholder
for a later milestone. Full register in `docs/pm/STAKEHOLDERS.md`.

## 8. Project manager and authority

Teammate: **Gustav Mahler** (`project-manager`). Authority: routine
schedule / cost / scope adjustments within 10 % of baseline; anything
beyond goes through `tech-lead` (**Nadia Boulanger**) to the customer.

## 9. Sponsor

Alex Keller. Authorized this charter 2026-04-19 per
`CUSTOMER_NOTES.md` § Q-0001.

## 10. Assumptions and constraints

- Brewhouse mini-PC exists, runs Linux, and has Python 3.11+.
- Tablet is a modern Chromium browser on the LAN.
- Brewer maintains the stack post-handoff; the stack (Python / FastAPI /
  HTMX / SQLite) is deliberately chosen to match that maintenance
  profile.
- No food-safety / regulatory submission on Milestone 1 path.
- No internet dependency.
- Brewer accepts PDF → browser-print for physical output.
