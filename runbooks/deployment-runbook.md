

# NovaPay Production Deployment Runbook

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and technical 
research. All procedures were reviewed and understood by the author.

## Purpose
This runbook must be usable by an on-call engineer with minimal context. Follow it 
sequentially — do not skip steps even under time pressure.

## Pre-Deployment Checklist (complete ALL before proceeding)

1. ☐ All CI pipeline gates passed (SAST, DAST, dependency scan, contract tests — see 
   Deliverable 1 & 3)
2. ☐ Deployment window verified — check blackout calendar (Deliverable 5); confirm NOT in 
   a blackout period
3. ☐ On-call engineer confirmed available and briefed on what's being deployed
4. ☐ Rollback plan confirmed — know which previous version/commit SHA to roll back to
5. ☐ Database migration (if any) has been tested in pre-prod with production-scale data
6. ☐ Dual approval obtained — Release Manager AND SRE Lead have both signed off
7. ☐ Monitoring dashboards open and visible (error rate, latency, DB pool status)
8. ☐ Incident communication channel ready (Slack channel or equivalent identified)

## Step-by-Step Execution Procedure

**Step 1: Confirm current state**
- Check current production version/commit SHA
- Confirm current error rate and latency baseline (this becomes your comparison point)

**Step 2: Initiate canary deployment**
- Trigger deployment pipeline (Stage 8 — see Deliverable 1)
- Confirm canary starts at 1-2% traffic weight (Deliverable 2)

**Decision point:** Do metrics stay within Category A thresholds (Deliverable 6) for 15 
minutes?
- **YES** → proceed to Step 3
- **NO** → automated rollback triggers; go to Incident Playbook

**Step 3: Progress through canary phases**
- Monitor each phase transition (5-10% → 25-50% → 100%) per the statistical gates in 
  Deliverable 2
- Do NOT manually override a failed statistical gate without CISO/Tech Lead consultation

**Step 4: Full rollout confirmation**
- Once at 100% traffic, begin the 24-hour bake period
- Continue monitoring — do not consider deployment "done" until bake period completes

## Post-Deployment Verification

1. Run smoke test suite against production (core flows: login, balance check, transfer)
2. Compare error rate and latency to pre-deployment baseline — should be equal or better
3. Confirm no Category A/B rollback triggers fired during rollout
4. Update deployment log with: commit SHA, deployer, approvers, start/end time, outcome
5. Close out the change record with final status

## If Anything Goes Wrong
**Stop here and go directly to `incident-playbook.md`.** Do not attempt manual fixes 
outside the documented rollback procedure (Deliverable 6) unless directed by SRE Lead.
