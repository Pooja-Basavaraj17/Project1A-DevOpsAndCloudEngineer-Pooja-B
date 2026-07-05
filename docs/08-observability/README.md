
# NovaPay Observability & DORA Metrics

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## The Four DORA Metrics

| DORA Metric | Definition | Elite Target | Measurement Method |
|---|---|---|---|
| Deployment Frequency | How often code deploys to production | Multiple per day | Count of production deployments per day |
| Lead Time for Changes | Commit to production deployment time | < 1 hour | Timestamp diff: commit → prod deploy |
| Change Failure Rate | % of deployments causing failures | < 5% | Rollbacks + hotfixes ÷ total deploys |
| MTTR | Time to restore after failure | < 1 hour | Incident duration: detection → resolution |

**NovaPay's current baseline vs. target:**

| Metric | Current State | Target (post-pipeline) |
|---|---|---|
| Deployment Frequency | Once every 2 weeks | Multiple per day |
| Lead Time for Changes | Unmeasured (manual SSH) | < 2 hours (Deliverable 7's velocity target) |
| Change Failure Rate | Unmeasured, but 3 incidents in Q4 2025 alone | < 5% |
| MTTR | 4.5 hours | < 15 minutes (Category A rollback: < 60 seconds) |

## Pipeline-Specific Metrics (beyond DORA)

- Build success rate (target > 95%)
- Flaky test rate and identification of top flaky tests
- Cache hit rate (build layer caching effectiveness)
- Gate pass rate per gate type (SAST/DAST/Dependency/Licence/Policy/Infra)
- False positive rate per scanning tool (tracked to avoid alert fatigue)
- Deployment duration (actual vs. estimated per Deliverable 1)
- Rollback frequency and trigger category distribution (A/B/C — see Deliverable 6)

## Three Dashboard Designs

### 1. Engineering Dashboard (real-time operations)
**Audience:** Dev team, SRE on-call
**Refresh:** Real-time (15s intervals)
**Contents:** Current deployment status, live canary traffic split, error rate/latency 
graphs, active alerts, gate pass/fail status for in-flight pipeline runs

### 2. Management Dashboard (weekly/monthly executive view)
**Audience:** CTO, VP Engineering
**Refresh:** Daily rollup
**Contents:** DORA metrics trend over time, deployment frequency chart, change failure rate 
trend, cost-per-deployment (FinOps angle), team velocity comparison

### 3. Regulatory Dashboard (audit-ready compliance view)
**Audience:** Head of Compliance, RBI Auditor
**Refresh:** Daily
**Contents:** Compliance gate pass rate (100% required — any bypass flagged), audit trail 
completeness, exception/override log with approver names and timestamps, SoD violation 
attempts (should be zero), incident count classified by severity with RBI-reportable 
incidents (> 30 min duration) highlighted separately

## Alerting Strategy

Severity-based routing (aligned with incident playbook severity levels):
- **SEV-1/Category A triggers** → PagerDuty immediate page to on-call + Slack #incidents-critical
- **SEV-2/Category B triggers** → PagerDuty page with 5-min escalation window + Slack #incidents
- **SEV-3/Category C** → Slack notification only, no page
- **SEV-4** → Ticket created, no real-time notification

## Sample Prometheus Query for DORA Lead Time Tracking

```promql
# Lead time for changes: time from commit to production deployment
histogram_quantile(0.50, 
  sum(rate(deployment_lead_time_seconds_bucket[7d])) by (le)
)
```
