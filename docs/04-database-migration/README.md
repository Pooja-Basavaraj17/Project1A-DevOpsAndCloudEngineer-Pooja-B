
# NovaPay Zero-Downtime Database Migration Strategy

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## Why This Matters for NovaPay
NovaPay's database (PostgreSQL 16) is shared between the blue and green environments 
(Deliverable 2) and read/written by multiple concurrent application versions during any 
canary or blue-green rollout. A direct schema change — like renaming or dropping a column 
— would instantly break whichever app version is still running old code, and could lock 
tables that hold financial transaction data. The expand-contract pattern eliminates this risk.

## The Expand-Contract Pattern

### Phase 1: EXPAND
Add new columns/tables alongside existing ones — fully backward compatible. Both App 
V(N-1) and App V(N) can operate against this schema simultaneously.

### Phase 2: MIGRATE
Backfill existing data into the new schema using throttled batch processing (idempotent, 
safe to retry). Deploy the app version that reads from the new schema.

### Phase 3: CONTRACT
Remove old columns/tables — but ONLY after ALL services have confirmed migration to the 
new schema. This step is **irreversible** and requires its own separate deployment with 
its own DBA approval gate.

## Version Compatibility Matrix

This matrix shows which app versions can safely run against which schema state — critical 
during any rollout where old and new app versions run concurrently:

| Schema State | App V(N-1) Compatible? | App V(N) Compatible? | Notes |
|---|---|---|---|
| Pre-Expand (original schema) | ✅ Yes | ❌ No | V(N) expects new column, not yet present |
| Expand complete (new + old columns coexist) | ✅ Yes | ✅ Yes | Safe state — both versions work |
| Migrate complete (data backfilled) | ✅ Yes | ✅ Yes | Still safe — old column still present |
| Contract complete (old column removed) | ❌ No | ✅ Yes | V(N-1) would break — only proceed once 100% on V(N) |

**Critical rule:** The Contract phase must NEVER execute while any instance of App V(N-1) 
is still running. This is verified via deployment tracking before the Contract migration 
is allowed to proceed.

## Worked Example: Encrypting Customer Email (Compliance-Driven Migration)

**Phase 1 — Expand** (`database/migrations/V2.0__expand_add_encrypted_email.sql`):
```sql
ALTER TABLE customer_profiles ADD COLUMN encrypted_email BYTEA;
CREATE INDEX CONCURRENTLY idx_customer_encrypted_email 
  ON customer_profiles (encrypted_email);
INSERT INTO schema_audit_log (migration_id, description, executed_by, phase)
  VALUES ('V2.0', 'Add encrypted_email column', current_user, 'EXPAND');
-- Do NOT drop the old email column yet - that happens in V2.2 (Contract phase)
```

**Phase 2 — Migrate** (`database/migrations/V2.1__migrate_backfill_encrypted_email.sql`):
Batch backfill with throttling (1000 rows per batch, 100ms pause between batches) to avoid 
production impact. Uses `SKIP LOCKED` to avoid lock contention with live traffic. Idempotent 
— safe to re-run if interrupted. Includes a verification check confirming no rows are left 
with an old email but no encrypted equivalent before the phase is marked complete.

**Phase 3 — Contract** (`database/migrations/V2.2__contract_drop_email.sql`, separate 
deployment, requires DBA approval gate):
```sql
-- Only runs after confirming 100% of app instances are on V(N) for 7+ days
ALTER TABLE customer_profiles DROP COLUMN email;
INSERT INTO schema_audit_log (migration_id, description, executed_by, phase)
  VALUES ('V2.2', 'Drop legacy email column', current_user, 'CONTRACT');
```

## Migration Tooling

**pgroll** is used for NovaPay's PostgreSQL 16 environment — chosen over `gh-ost` (which is 
MySQL-specific) or manual scripts because it natively supports expand-contract as a first-class 
workflow and generates a versioned migration history automatically.

- Online schema migration — avoids table-level locks that would block live traffic
- **Abort criteria:** if migration measurably impacts query latency by more than 20%, the 
  migration aborts automatically and pages the on-call DBA
- All migrations tracked in `schema_audit_log` table — satisfies RBI Section 6.1 (audit 
  trail requirement)

## Handling 100M+ Row Tables (per project scenario requirement)

For NovaPay's largest financial tables (transaction history, potentially 100M+ rows):
- Batch size reduced to 500 rows per batch (vs. 1000 for smaller tables) to limit lock 
  contention window
- Backfill runs during low-traffic windows only (outside blackout calendar — see Deliverable 5)
- Progress tracked and resumable — a batch job failure does not require restarting from row 0
- Full backfill estimated at 100M rows ÷ 500 rows/batch × ~200ms/batch (100ms processing + 
  100ms throttle) ≈ 5.5 hours total, run as a background job independent of any deployment 
  window — this is NOT part of the sub-2-hour deployment pipeline target, since backfill is 
  a separate, longer-running background process
