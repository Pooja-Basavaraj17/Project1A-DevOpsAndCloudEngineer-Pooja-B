
# NovaPay Incident Response Playbook

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All procedures were reviewed and understood by the author.

## Severity Classification

| Severity | Definition | Response Time | Escalation Path |
|---|---|---|---|
| SEV-1 | Complete service outage or data integrity risk | < 5 minutes | CTO + CISO + VP Eng |
| SEV-2 | Major feature degradation affecting > 10% users | < 15 minutes | VP Eng + SRE Lead |
| SEV-3 | Minor degradation, workaround exists | < 1 hour | SRE on-call + Tech Lead |
| SEV-4 | Cosmetic issue, no user impact | Next business day | Assigned engineer |

## 7-Step Incident Response Workflow

1. **Detect** — alert fires (automated) or is reported (manual)
2. **Triage** — classify severity using the table above within the response time window
3. **Communicate (initial)** — post to internal Slack incident channel; if SEV-1/2, update 
   external status page
4. **Contain** — trigger rollback if not already automatic (see Deliverable 6); isolate 
   affected component if possible
5. **Communicate (ongoing)** — updates every 30 minutes for SEV-1, hourly for SEV-2, until resolved
6. **Resolve** — confirm service restored via smoke tests and metric comparison to baseline
7. **Communicate (resolution)** — send resolution notice with impact summary to all 
   stakeholders notified during the incident

## Communication Templates

**Initial acknowledgement (internal):**
> 🔴 SEV-[X] Incident declared at [time]. [Brief description]. Investigating. Updates 
> every [30min/hourly] in this thread. IC: [name].

**Regular update:**
> Update [time]: [What we know now]. [What we're doing]. Next update at [time].

**Resolution notification:**
> ✅ Incident resolved at [time]. Duration: [X min]. Root cause: [brief]. Impact: [X users/
> transactions affected]. Full postmortem to follow within 48h.

## Postmortem Report Template

- **Incident ID & Date:**
- **Severity:**
- **Duration:** (detection to resolution)
- **Timeline:** (timestamped sequence of detection → actions → resolution)
- **Root Cause:**
- **What Went Well:**
- **What Went Wrong:**
- **Which pipeline gate, if any, should have caught this?**
- **Action Items:** (owner + due date for each)

---

## Worked Example: The Friday 5PM Incident Simulation

**Scenario (per project brief):** Friday, 5:07 PM IST. A developer pushes a "critical 
hotfix" that bypassed staging. Canary has been running 8 minutes when three alerts fire 
simultaneously: HTTP 500 error rate at 12% (threshold 5%, Severity CRITICAL), PostgreSQL 
connection pool exhaustion on primary (Severity HIGH), downstream payment gateway timeout 
rate at 35% (Severity CRITICAL).

**Timeline:**

| Time | Action |
|---|---|
| T+0 | Three alerts fire simultaneously. Auto-classified SEV-1 (payment-affecting, multiple critical signals) |
| T+30s | Category A rollback trigger condition met (5xx rate 12% > 5% threshold) — automatic rollback initiates per Deliverable 6 |
| T+45s | Traffic reverted to previous stable version; canary weight set to 0% |
| T+2m | Internal Slack incident channel updated: "SEV-1 declared, automatic rollback completed, investigating root cause" |
| T+5m | Smoke tests confirm previous version healthy; error rate returning to baseline |
| T+8m | External status page updated (SEV-1 threshold requires this) |
| T+15m | Root cause identified: hotfix bypassed staging, so contract tests (Deliverable 1, Stage 5) and DAST (Stage 6) never ran — a database query change in the hotfix was incompatible with current connection pool configuration |
| T+30m | First regular update posted per SEV-1 cadence |
| T+45m | Incident marked resolved — automatic rollback had already restored service by T+45s; remaining time was root-cause investigation, not ongoing customer impact |

**Root Cause Analysis — What Gate Was Missing?**

The hotfix path **bypassed staging entirely**, which means it skipped:
- Stage 5 (Integration & Contract Testing) — would have caught the connection pool 
  incompatibility before reaching any live traffic
- Stage 6 (DAST) — not directly relevant to this specific failure, but also skipped

**Was this failure preventable by pipeline design, or was it a process violation?**
This was a **process violation**, not a pipeline design gap. Per Deliverable 1, the 
architecture explicitly states hotfixes should have an "expedited but not bypassed" 
pipeline — this incident represents someone bypassing the required gates, not the gates 
failing to exist. The genuine positive: the automated Category A rollback (Deliverable 6) 
limited actual customer impact to under 60 seconds, even though the hotfix itself was 
improperly fast-tracked.

**Action Items:**
- Enforce technical guardrail so hotfix branches CANNOT skip staging/contract tests, even 
  under manual override pressure (owner: Platform team, due: 2 weeks)
- Add a specific pre-deploy check for connection-pool-affecting query changes (owner: DBA 
  team, due: 1 month)
