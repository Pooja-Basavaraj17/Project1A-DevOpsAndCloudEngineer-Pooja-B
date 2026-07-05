
# NovaPay Automated Rollback Specification

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## Why Automated Rollback Matters
Automated rollback is the safety net that makes rapid, frequent deployment possible. 
Without it, every deployment carries the risk of NovaPay's current 4.5-hour MTTR repeating 
itself. Three categories of rollback triggers exist, based on severity and required 
response speed.

## Category A — Immediate (< 60 seconds, zero human intervention)

| Trigger | Threshold |
|---|---|
| HTTP 5xx error rate | > 5% for 60 seconds |
| Health check failure | 3 consecutive failures |
| OOM kills | Any occurrence |
| CrashLoopBackOff | Any occurrence |
| Database connection pool exhaustion | Pool at 100% capacity |

**Action:** Instant traffic re-routing to previous stable version. No human approval 
required — the system self-heals before a human could realistically react.

## Category B — Escalated (< 15 minutes, alert + conditional auto-rollback)

| Trigger | Threshold |
|---|---|
| Latency p99 | > 2x baseline for 5 minutes |
| Error budget burn rate | > 10x normal for 10 minutes |
| Transaction success rate | Drops > 2% below baseline |
| Resource saturation | CPU > 90% or memory > 85% sustained 5 minutes |

**Action:** Alert on-call engineer immediately. If no acknowledgement within the escalation 
window (5 minutes), automated rollback executes without waiting further.

## Category C — Manual Decision (human judgment required)

| Trigger | Why It Needs Human Judgment |
|---|---|
| Gradual degradation below automated thresholds | Pattern isn't clear-cut enough for automation |
| Customer support reports | Requires correlation with technical signals |
| Retroactive compliance failure | May require careful assessment, not instant action |
| Downstream dependency correlation | Root cause may be external to NovaPay's systems |

**Action:** Surface as a warning to on-call + SRE Lead. No automatic action — a human 
evaluates the full context before deciding whether to roll back.

## 8-Step Rollback Execution Workflow

1. **Detect** — automated monitoring identifies a trigger condition (Category A/B) or a 
   human raises a concern (Category C)
2. **Correlate** — check if multiple signals point to the same root cause (e.g., DB pool 
   exhaustion + 5xx spike are likely related, not independent issues)
3. **Freeze** — pause any in-progress canary promotion immediately; do not increase traffic 
   weight further
4. **Rollback** — revert traffic to the last known-stable version (previous canary step or 
   full previous release, depending on severity)
5. **Verify** — run post-rollback smoke tests to confirm the previous version is healthy
6. **Notify** — alert on-call, SRE Lead, and (for Category A/B) the incident channel with 
   automated summary of what triggered the rollback
7. **Incident** — open a formal incident ticket, classified by severity (see runbooks/
   incident-playbook.md)
8. **Postmortem** — schedule blameless postmortem within 48 hours for any Category A or B 
   rollback (see runbooks/incident-playbook.md for the postmortem template)

## Post-Rollback Verification
- **Smoke tests:** confirm core transaction flows (login, balance check, transfer) succeed 
  on the rolled-back version
- **Metric comparison:** confirm error rate and latency return to baseline within 5 minutes 
  of rollback completion
- **Customer impact assessment:** estimate number of affected transactions/users during the 
  incident window, for both internal reporting and potential RBI incident disclosure 
  (required for incidents exceeding 30-minute duration, per RBI reporting norms)

## Sample Prometheus Alerting Rule (Category A example)

```yaml
groups:
  - name: novapay-rollback-triggers
    rules:
      - alert: HighErrorRateImmediateRollback
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[1m]))
          /
          sum(rate(http_requests_total[1m])) > 0.05
        for: 60s
        labels:
          severity: critical
          rollback_category: A
        annotations:
          summary: "5xx error rate exceeds 5% for 60s - triggering automatic rollback"
          
      - alert: DatabasePoolExhaustion
        expr: pg_pool_connections_active / pg_pool_connections_max > 0.95
        for: 30s
        labels:
          severity: critical
          rollback_category: A
        annotations:
          summary: "Database connection pool near exhaustion - triggering automatic rollback"
```
