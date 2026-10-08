# Threat Modeling Portfolio

Structured threat models for systems at different scales, built using the STRIDE methodology. Each model includes architecture documentation, data flow diagrams with trust boundaries, systematic threat enumeration, risk ratings, and mapped mitigations.

## Models

| Model | Target | Key Threat Surfaces |
|-------|--------|-------------------|
| [Flask Demo App](models/flask-demo-app/) | Intentionally vulnerable Python web app | SQL injection, XSS, hardcoded secrets, insecure deserialization |
| [Enterprise E-Commerce Platform](models/enterprise-ecommerce/) | Multi-tier retail platform (SecureCart) | Payment processing, PII handling, API security, third-party integrations |
| [CI/CD Pipeline](models/ci-cd-pipeline/) | GitHub Actions DevSecOps pipeline | Supply chain attacks, secrets exfiltration, runner compromise, dependency poisoning |
| [oauth2-proxy](models/oauth2-proxy/) | CNCF authentication reverse proxy | Session hijacking, identity header spoofing, cookie secret compromise, OAuth flow abuse, skip-auth bypass |

## Methodology

All models follow the [STRIDE framework](methodology/stride-framework.md) with a consistent risk rating system. A reusable [threat model template](templates/threat-model-template.md) is included for applying the same process to new systems.

## How to Read These Models

Each model directory contains:

- **README.md** — System overview and architecture description
- **data-flow-diagram.md** — Mermaid DFDs with labeled trust boundaries
- **threat-analysis.md** — STRIDE threats enumerated per component with risk ratings
- **mitigations.md** — Controls mapped to each identified threat

## Related Projects

- [devsecops-pipeline-demo](https://github.com/adamtamenne/devsecops-pipeline-demo) — The working 5-stage security pipeline that the Flask app and CI/CD pipeline models reference
