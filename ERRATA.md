
# ERRATA — Deliberate Errors Found

## AI Attribution
Error identification was conducted through AI-assisted review and independent web 
verification of factual claims (DORA benchmarks, incident timelines) against the source document.

## Error 1 — Part C: Cloudflare Case Study Outage Duration
**Location:** Case Study 3, Cloudflare Global Outage section
**Error:** The narrative states the outage "caused Cloudflare to drop approximately 50% of 
global HTTP traffic for **27 minutes**" in one place, while an explicit note elsewhere in 
the same case study says: *"The original version of this document states the outage lasted 
21 minutes. The actual duration was 27 minutes."*
**Correction:** The correct, verified duration is 27 minutes (confirmed by Cloudflare's own 
public incident postmortem).
**Why it matters:** Getting incident duration wrong undermines the accuracy of the "MTTR/
recovery time" case study lesson — precision in incident timelines is exactly what a real 
RBI auditor would scrutinise.

## Error 2 — Part D: Total Hours Arithmetic Inconsistency
**Location:** Section D1, Project Structure Overview
**Error:** States "6–9 hours per day, **100–135 hours** over 15 days." 
Mathematically: 6 hours/day × 15 days = 90 hours (not 100). Only the upper bound (9 × 15 = 
135) is internally consistent.
**Correction:** The range should read "90–135 hours over 15 days" to be arithmetically correct.
**Why it matters:** This is exactly the kind of unchecked arithmetic error that a compliance/
audit-focused role must catch — the whole premise of this project is precision under 
regulatory scrutiny.

## Error 3 — Part A: DORA Elite "Lead Time for Changes" Benchmark (candidate, moderate confidence)
**Location:** Section A5, DORA Metrics table
**Claim in document:** Elite target for "Lead Time for Changes" is "< 1 hour"
**Finding:** Current DORA research (2024 State of DevOps Report) defines the elite 
benchmark for Lead Time for Changes as **"less than one day,"** not one hour. Note: older 
DORA/Accelerate research (2018-2021) did use "<1 hour" as the elite threshold, so this may 
reflect an outdated-but-not-technically-"wrong" figure rather than a deliberately planted error.
**Correction (if this is confirmed as the intended error):** Should read "< 1 day" per 
current DORA benchmarks.
**Confidence:** Moderate — flagging this as the most likely Part A candidate found through 
research, while noting it may not be the specific error the document's authors intended.
