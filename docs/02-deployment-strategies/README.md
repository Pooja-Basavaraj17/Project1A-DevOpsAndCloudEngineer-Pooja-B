
# NovaPay Deployment Strategies: Blue-Green & Canary

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## Blue-Green Deployment

Two identical production environments run at all times. One (blue) serves 100% of live 
traffic while the other (green) is idle or receiving the new deployment.

### Infrastructure Topology
- Two Kubernetes namespaces: `novapay-prod-blue` and `novapay-prod-green`
- Shared database namespace: `novapay-shared` (both environments read/write the same DB)
- Traffic routing: Istio VirtualService controls which colour receives 100% of traffic

### Traffic Switching Protocol (5-Step Sequence)
1. Deploy new version fully into the idle colour (e.g., green) — zero live traffic yet
2. Run automated smoke tests against green in isolation
3. Update the Istio VirtualService manifest to route 100% of traffic to green (atomic switch)
4. Keep blue running, fully intact, for a defined rollback window (default: 30 minutes)
5. After the rollback window with no issues, blue is decommissioned or repurposed for the next release

### Session Management
Distributed session store via **Redis cluster (3 nodes)** — sessions are not tied to a 
specific pod/colour, so a traffic switch never logs users out or loses their session state.

### Long-Running Transaction Handling
Payment processing jobs in flight during a switch are drained gracefully:
- HTTP requests: 30–60 second connection draining timeout
- Payment settlement jobs: up to 5-minute timeout, allowing in-flight transactions to complete 
  before the old colour stops accepting new work

### Shared Database Consideration
Since both blue and green share the same database, all schema changes must be 
**backward-compatible** during the transition window — this is why the expand-contract 
migration pattern (Deliverable 4) is mandatory, not optional.

## Canary Deployment

Canary deployments route a small percentage of traffic to the new version, increasing 
progressively while health metrics stay within thresholds.

### Canary Progression

| Phase | Traffic % | Duration | Success Criteria | Auto Action |
|---|---|---|---|---|
| Canary | 1–2% | 15 min | Error rate < 0.1%, p99 latency < 200ms | Proceed or auto-rollback |
| Early Adopter | 5–10% | 30 min | Error rate < 0.05%, no critical alerts | Proceed or auto-rollback |
| Expansion | 25–50% | 60 min | All SLOs met, no degradation vs baseline | Proceed to full rollout |
| Full Rollout | 100% | 24 hr bake | Complete SLO compliance for 24 hours | Mark deployment stable |

### Statistical Analysis for Promotion Decisions

Manual eyeballing of metrics is not sufficient for a banking system — promotion between 
canary phases is decided using statistical tests, not gut feeling:

- **Welch's t-test** compares latency distributions between the canary and baseline 
  populations. Unlike a simple average comparison, it accounts for unequal variance between 
  the small canary sample and the larger baseline sample — appropriate here since canary 
  traffic (1-50%) is much smaller than baseline traffic.
- **Chi-squared test** compares error rate *proportions* between canary and baseline — 
  appropriate because error rate is a categorical (success/failure) outcome, not a continuous 
  measurement like latency.
- **95% confidence interval** is required before automated promotion to the next phase — if 
  the test doesn't reach 95% confidence that the canary is performing at least as well as 
  baseline, the phase holds (does not auto-promote) and pages the on-call engineer.
- **Rolling 7-day production baseline** is used for comparison, not a single point-in-time 
  snapshot — this avoids false positives/negatives from unusual traffic on any single day.
- **Multi-metric weighted composite score** combines latency, error rate, and resource 
  utilisation into one score, so no single metric can be gamed or accidentally ignored.

### Why Canary Over Blue-Green as Primary Strategy

Canary is used as the **default/primary** strategy because it limits blast radius — a bad 
release only ever affects the small percentage of users in the current phase before being 
caught, versus blue-green's atomic 100% switch. Blue-green remains available as a **fallback 
for critical hotfixes** where canary's gradual timeline (110+ minutes to full rollout) is too 
slow for the urgency of the fix.
