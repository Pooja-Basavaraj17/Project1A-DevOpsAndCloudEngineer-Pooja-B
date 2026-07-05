# Case Study Responses — NovaPay Pipeline Design Applications

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## Case Study 1: Knight Capital — Deployment Verification Design

**Task:** Design a deployment verification step that would have prevented the Knight 
Capital disaster.

**Design:**
A post-deployment verification job runs automatically as part of Stage 8 (Deployment & 
Verification, see Deliverable 1) before any deployment is marked successful:

1. **Fleet image hash check:** Query every running pod's container image digest (SHA256) 
   and compare against the target deployment's expected digest. Any mismatch across the 
   fleet fails verification immediately.
2. **Configuration consistency check:** Compare each pod's mounted ConfigMap/Secret 
   versions against the expected version for this release — catches partial config rollouts.
3. **Automated kill-switch:** If step 1 or 2 detects any mismatch, the deployment 
   automatically halts and the mismatched pod(s) are cordoned (removed from traffic) within 
   seconds — equivalent to Category A rollback (Deliverable 6).
4. **Pre-deployment inventory:** Before starting any deployment, the pipeline records a 
   snapshot of currently-running versions across all pods. Post-deployment, this snapshot is 
   compared against the target state — any pod NOT matching the target after the deployment 
   window closes is flagged as a stuck/failed rollout, not silently ignored.

This directly prevents Knight Capital's failure mode: a partial, inconsistent deployment 
across a fleet going undetected because no automated check compared actual running state 
against intended state.

## Case Study 2: YES Bank — Observability Stack Design

**Task:** Design an observability stack that would have detected YES Bank's UPI failures 
within 30 seconds.

**Design:**
- **Prometheus alerting rules:** Synthetic transaction probes run every 10 seconds against 
  UPI transaction endpoints (not just server health checks) — checking actual transaction 
  success end-to-end, not just "is the server up." Alert fires if 3 consecutive synthetic 
  transactions fail (30-second detection window).
- **Escalation path:** SEV-1 classification (per incident playbook, Deliverable 7) — pages 
  on-call within 5 minutes, auto-escalates to VP Engineering + CISO if unacknowledged in 15 minutes.
- **Automated status page updates:** Integrated with the alerting system — a confirmed SEV-1 
  UPI failure automatically posts an initial status page update within 60 seconds of 
  detection, rather than waiting for manual confirmation.
- **RBI regulatory notification workflow:** Any incident exceeding 30 minutes duration 
  automatically triggers a compliance workflow ticket requiring the Head of Compliance to 
  review and initiate the formal RBI incident disclosure process — this is tracked as a 
  compliance gate outcome, not left to individual judgment on whether to notify.

This directly addresses YES Bank's core failure: incidents were detected by customers, not 
systems — synthetic transaction monitoring closes that gap by testing the actual user 
journey, not just infrastructure health.

## Case Study 3: Cloudflare — Configuration Change Pipeline Design

**Task:** Design a configuration change pipeline for NovaPay's WAF/security rules.

**Design:**
All configuration changes (WAF rules, feature flags, routing rules) go through the **same 
CI/CD pipeline as application code** — no separate, less-scrutinized path exists.

1. **Canary testing for config changes:** A new WAF rule deploys first to a single canary 
   environment/region, never globally in one shot.
2. **Performance baseline comparison:** Before promoting beyond canary, CPU, memory, and 
   latency on the canary environment are compared against a pre-change baseline. Any 
   regression beyond 15% blocks promotion.
3. **Independent rollback mechanism:** The rollback path for configuration changes does NOT 
   depend on the same infrastructure the config change affects — for example, WAF rule 
   rollback is triggered via a separate lightweight control-plane API call, not requiring the 
   main deployment pipeline (which could itself be affected by the same CPU exhaustion the 
   bad config caused).
4. **Circuit breaker activation:** If CPU on any node exceeds 80% within 60 seconds of a 
   config change being applied, the circuit breaker automatically reverts that specific 
   config change and isolates the affected nodes from new traffic — independent of the 
   canary system, as a last-resort safety net.

This directly prevents Cloudflare's failure mode: treating config changes as lower-risk than 
code, deploying them globally without canary, and having a rollback path that depended on 
the very system the bad config had crippled.

## Case Study 4: SBI YONO — Deployment Blackout Calendar Design

**Task:** Design a deployment blackout calendar for NovaPay.

**Design:** (Full detail also in Deliverable 5 — summarized here for case study completeness)

**Blackout periods (no production deployments):**
- Salary days: 1st, 7th, 15th of each month
- Month-end processing: 28th–31st
- Major festivals: Diwali, Eid, Christmas, Holi
- RBI settlement windows and regulatory filing deadlines
- Planned marketing campaign launch windows

**Auto-scaling triggers (active always, blackout or not):**
- CPU > 70% → scale out
- Queue depth > 1000 → scale out
- p99 latency > 300ms → scale out + alert

**Mandatory pre-deployment performance test requirement:**
Any deployment scheduled within 48 hours of a known high-traffic window (per the calendar 
above) requires an additional load test simulating 3–5x normal traffic before the deployment 
is permitted to proceed past the Staging → Pre-Prod gate (Deliverable 5).

This directly prevents SBI YONO's failure mode: predictable traffic spikes (salary days) 
not being tested against, and deployments happening without regard to traffic timing.

## Cross-Case Synthesis — Applied to NovaPay

| Case Study | Primary Failure | NovaPay's Corresponding Control |
|---|---|---|
| Knight Capital | Manual deployment, no verification | Automated deployment (Deliverable 1) + fleet consistency verification (above) |
| YES Bank | Missing compliance, no observability | Automated compliance gates (Deliverable 3) + observability stack (Deliverable 8) |
| Cloudflare | No canary + slow rollback | Progressive canary (Deliverable 2) + independent rollback (above) |
| SBI YONO | No load testing + bad deployment timing | Performance gates + deployment blackout calendar (Deliverable 5) |
