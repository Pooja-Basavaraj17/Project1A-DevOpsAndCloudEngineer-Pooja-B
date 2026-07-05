
# NovaPay Environment Promotion Workflow

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All design decisions were reviewed and understood by the author.

## The Four-Environment Model

| Environment | Purpose | Data Profile | Access Control | Deploy Trigger |
|---|---|---|---|---|
| Development | Feature development, unit testing | Synthetic/mock data only | All developers | Automatic on PR merge |
| Staging | Integration testing, DAST, performance | Anonymised production-like data | Dev team + QA | Automatic after dev gates pass |
| Pre-Production | UAT, compliance verification, regulatory | Masked production data subset | QA + Compliance + DBA | Manual approval after staging |
| Production | Live customer-facing environment | Real production data | SRE + Release Manager only | Dual approval (RM + SRE Lead) |

## Promotion Criteria: Dev → Staging
- All unit tests pass (100% pass rate, 0 test failures tolerated)
- Code coverage ≥ 80% line coverage, ≥ 70% branch coverage
- SAST scan: 0 Critical vulnerabilities, ≤ 2 High findings
- Build artefact signed and pushed to container registry with SemVer tag
- **Automated promotion** — no human approval required if all gates pass

## Promotion Criteria: Staging → Pre-Prod
- All integration tests pass, including consumer-driven contract tests (Pact)
- DAST scan complete with 0 Critical/High findings from OWASP Top 10
- Performance test: p99 latency < 500ms under 2x expected production load
- Dependency scan: 0 Critical CVEs, SBOM generated and archived
- Licence compliance check passed (no GPL/AGPL dependencies detected)
- **Tech Lead approval required** (manual gate)

## Promotion Criteria: Pre-Prod → Production
- UAT sign-off from Product Owner (formal written approval)
- All regulatory compliance gates passed (RBI + PCI-DSS mapping verified — see Deliverable 3)
- Database migration tested and validated in pre-prod with production-scale data
- Deployment runbook reviewed, updated, and signed off by SRE Lead
- Change Advisory Board (CAB) approval OR pre-approved change category
- **Dual approval: Release Manager AND SRE Lead** (segregation of duties enforcement)
- Deployment window verification: not in blackout period, not during peak hours
- On-call engineer confirmed available and briefed on the deployment

## Configuration Management Strategy

**Principle: "Same artefact, different config."** The same container image is promoted 
through all four environments — only configuration changes, never code.

- **Secrets management:** HashiCorp Vault, with automatic rotation (90-day for database 
  passwords, 30-day for API keys). No plaintext secrets in Git, Helm values, or K8s manifests.
- **Configuration hierarchy:** base config (shared) → environment override (dev/staging/
  pre-prod/prod) → service override (per-service). Implemented via Helm values files: 
  `values.yaml` (base), `values-staging.yaml`, `values-production.yaml`.
- **Feature flags:** environment-aware toggles. New features deploy everywhere but stay off 
  in production until ready — gradual rollout (1% → 10% → 50% → 100%) mirrors the canary 
  pattern from Deliverable 2.
- **Configuration drift detection:** ArgoCD compares Git-declared state vs. live cluster 
  state every 3 minutes; any drift triggers a Slack notification and optional auto-sync.
- **No environment-specific branches:** the same `main` branch produces the same container 
  image for all environments — differences live only in configuration.

## Deployment Blackout Calendar

No deployments to production during these windows (based on real-world lessons from the 
SBI YONO case study — see case study analysis in evidence/):
- Salary days: 1st, 7th, 15th of each month
- Month-end processing: 28th–31st
- Major festivals: Diwali, Eid, Christmas, Holi
- RBI settlement windows and regulatory filing deadlines
- Any planned marketing campaign launch window

**Auto-scaling triggers** (active regardless of blackout status): CPU > 70%, queue depth 
> 1000, p99 latency > 300ms.

**Mandatory performance test requirement:** any deployment scheduled within 48 hours of a 
known high-traffic window requires an additional load test simulating 3–5x normal traffic 
before promotion to production is permitted.
