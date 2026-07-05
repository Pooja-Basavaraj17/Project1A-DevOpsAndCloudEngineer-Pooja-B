# Project1A-DevOpsAndCloudEngineer-Pooja-B
# NovaPay Digital Bank — Zero-Downtime CI/CD Pipeline with Compliance Gates

**Project:** ZeTheta WorkBridge — Project 1A, DevOps & Cloud Engineer
**Author:** Pooja Basavaraj
**Status:** Complete

## Executive Summary

NovaPay Digital Bank, an RBI-licensed digital bank, currently deploys via manual SSH once 
every two weeks, with a 4.5-hour Mean Time to Recovery and 17 open RBI audit 
non-conformances. This repository designs a production-grade, zero-downtime CI/CD pipeline 
that transforms this into a system capable of deploying multiple times per day, recovering 
from incidents in minutes, and producing complete compliance evidence for every change.

The architecture spans eight canonical pipeline stages — source control through deployment 
and verification — with SAST, DAST, container scanning, and policy gates as hard blocking 
conditions, not optional add-ons. It implements both blue-green and canary deployment 
strategies with statistically-driven automated rollback, expand-contract database migrations 
capable of handling 100M+ row tables, and six automated compliance gates mapped to RBI 
Master Directions, PCI-DSS v4.0, and segregation of duties requirements. The design achieves 
a sub-2-hour commit-to-production time while targeting the availability demanded by India's 
UPI-scale payment infrastructure.

## Table of Contents

- [Deliverable 1: Pipeline Architecture](./docs/01-pipeline-architecture/architecture.md)
- [Deliverable 2: Deployment Strategies](./docs/02-deployment-strategies/README.md)
- [Deliverable 3: Compliance Gates](./docs/03-compliance-gates/README.md)
- [Deliverable 4: Database Migration](./docs/04-database-migration/README.md)
- [Deliverable 5: Environment Promotion](./docs/05-environment-promotion/README.md)
- [Deliverable 6: Rollback Specification](./docs/06-rollback-specification/README.md)
- [Deliverable 7: Runbook & Incident Playbook](./docs/07-runbook-playbook/README.md)
- [Deliverable 8: Observability & DORA Metrics](./docs/08-observability/README.md)
- [Case Study Responses](./docs/case-studies-response.md)
- [ERRATA — Deliberate Errors Found](./ERRATA.md)
- [TRC Presentation](./evidence/trc-presentation.pdf)
- [Self-Assessment](./evidence/self-assessment.md)
- [Reflections](./evidence/reflections.md)

## Architecture Overview

![Pipeline Architecture](./docs/01-pipeline-architecture/diagrams/pipeline-architecture.png)

Eight stages — Source Control, Build, SAST, Dependency/Container Scanning, Integration/
Contract Testing, DAST, Policy/Compliance Gates, and Deployment/Verification — with Stages 
3 and 4 running in parallel to protect the commit-to-production time budget. Full detail in 
Deliverable 1.

## Repository Structure
