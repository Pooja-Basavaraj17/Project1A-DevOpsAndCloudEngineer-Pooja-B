
# NovaPay Compliance Gates: RBI, PCI-DSS v4.0, and Segregation of Duties

## AI Attribution
This document was developed with AI assistance (Claude) for drafting and regulatory 
research synthesis. All mappings were reviewed and understood by the author.

## RBI Master Direction on IT Risk — Control Mapping

| RBI Section | Requirement Summary | Pipeline Control Mapping |
|---|---|---|
| 4.2 | Change management: testing, approval, rollback procedures | CI/CD gates + dual approval + automated rollback |
| 4.3 | Segregation of duties between development and deployment | RBAC in pipeline + separate deploy credentials |
| 5.1 | Vulnerability assessment must be performed regularly | SAST + DAST + dependency scanning gates |
| 5.4 | Encryption of data in transit and at rest | Policy gate: TLS 1.3 + encryption verification |
| 6.1 | Comprehensive audit trails for all system changes | Pipeline audit logging + immutable change record |
| 6.3 | Incident management and business continuity | Incident playbook + automated rollback + DR design |
| 7.2 | Third-party risk management | Licence compliance + SBOM + vendor security assessment |

## PCI-DSS v4.0 — Requirement Mapping

| Req # | Title | Pipeline Implementation |
|---|---|---|
| 6.2 | Bespoke Software Security | SAST gate + mandatory peer review |
| 6.3 | Security Vulnerabilities | Dependency scanning + CVE gating |
| 6.4 | Public-Facing Web App Protection | DAST gate + WAF integration |
| 6.5 | Change Management Processes | Environment promotion workflow + dual approvals |
| 10.2 | Audit Log Recording | Pipeline audit logging to immutable store |
| 11.3 | Penetration Testing | DAST integration + periodic pen test schedule |
| 12.6 | Security Awareness Training | Compliance training verification gate |

## The 6 Automated Compliance Gates

Each gate below has: a precise pass/fail threshold, remediation guidance, a formal 
exception workflow with time-bound approval, and a mapping to specific regulatory 
requirements above.

| Gate | Tool | Threshold | On Failure | Exception Process |
|---|---|---|---|---|
| SAST | SonarQube | 0 Critical, ≤2 High, ≥80% coverage | Pipeline blocked, auto-ticket created | CISO approval within 24h |
| DAST | OWASP ZAP | 0 Critical/High from OWASP Top 10 | Pipeline blocked | Risk acceptance form + TRC review |
| Dependency | Trivy | 0 Critical CVE, SBOM generated | Pipeline blocked if CVSS ≥ 9.0 | 72h remediation window |
| Licence | FOSSA/Scancode | No GPL/AGPL/SSPL dependencies | Legal review triggered | Legal team sign-off |
| Policy | OPA/Kyverno | All K8s policies pass | Deployment rejected | Dual approval override |
| Infra | Checkov/Terraform | No privileged containers, resource limits set | PR blocked | Tech Lead exemption |

## Segregation of Duties (SoD) Enforcement

SoD is enforced technically, not just as a written policy:
- **RBAC**: developers have write access to code repositories but cannot approve their own 
  pull requests or trigger production deployments
- **Separate deploy credentials**: the identity/service account that deploys to production 
  is different from any individual developer's credentials — deployment happens via a 
  pipeline service account, never a personal login
- **Dual approval on production**: Release Manager AND SRE Lead must both approve — no single 
  person can complete a production deployment alone
- **Audit trail**: every approval, override, and exception is logged immutably, tied to a 
  named individual and timestamp, satisfying RBI Section 6.1's audit trail requirement

## Gate Orchestration

Gates execute in this order within the pipeline (see Deliverable 1 for full stage context):
1. SAST and Dependency scanning run **in parallel** (Stage 3 & 4)
2. Licence compliance check runs as part of the Dependency scan job
3. DAST runs after staging deployment (Stage 6)
4. Policy (OPA/Kyverno) and Infra (Checkov) gates run at Stage 7, immediately before the 
   compliance approval gate
5. Any gate failure halts the pipeline at that stage — no downstream stage executes until 
   the failure is resolved or a formal exception is granted
