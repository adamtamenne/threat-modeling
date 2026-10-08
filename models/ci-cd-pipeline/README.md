# Threat Model: GitHub Actions DevSecOps Pipeline

**System:** CI/CD security scanning pipeline built on GitHub Actions
**Date:** October 2026
**Methodology:** STRIDE

## System Overview

This threat model covers a GitHub Actions-based DevSecOps pipeline that automates security scanning across five stages: secrets detection, static analysis (SAST), software composition analysis (SCA), container image scanning, and dynamic application security testing (DAST). The pipeline runs on every push and pull request, uploads SARIF results to GitHub's Security tab, and is designed for a small team shipping a containerized Python/Flask application.

### Architecture

| Component | Technology | Description |
|-----------|-----------|-------------|
| Source Repository | GitHub | Hosts application code, Dockerfile, workflow definitions, and requirements files |
| Workflow Engine | GitHub Actions | Orchestrates the five-stage pipeline on `ubuntu-latest` runners |
| Secrets Store | GitHub Secrets | Stores API keys for third-party scanners (e.g. `SNYK_TOKEN`) |
| Stage 1 — Secrets Scan | Gitleaks | Scans commit history and working tree for hardcoded secrets |
| Stage 2 — SAST | Semgrep | Static analysis for injection flaws, insecure patterns, and code quality |
| Stage 3 — SCA | Snyk CLI | Checks Python dependencies against known vulnerability databases |
| Stage 4 — Container Scan | Trivy (Aqua) | Scans the built Docker image for OS-package and library vulnerabilities |
| Stage 5 — DAST | OWASP ZAP | Runs an active/passive scan against the live containerized application |
| Results Aggregation | GitHub Security Tab | Collects SARIF uploads from each stage into a unified code scanning view |
| Artifact Storage | GitHub Actions Artifacts | Stores scan reports (SARIF, HTML, JSON) for download and review |

### Data Classification

| Data Type | Classification | Handling |
|-----------|---------------|----------|
| Application source code | Confidential | Checked out on ephemeral runner; never persists beyond job |
| Scanner API tokens (SNYK_TOKEN) | Secret | Stored in GitHub Secrets; injected as environment variables at runtime |
| SARIF scan results | Internal | Uploaded to GitHub Security tab; may contain file paths and code snippets |
| Docker image layers | Internal | Built and scanned in-job; pushed to registry only if a deploy stage exists |
| Workflow definition files | Internal | YAML files in `.github/workflows/`; changes trigger pipeline runs |
| Runner environment metadata | Internal | OS version, installed packages, network config; ephemeral but observable during job |

### Pipeline Flow

```
Push / PR
  │
  ├─► Stage 1: Gitleaks (secrets scan)
  ├─► Stage 2: Semgrep (SAST)
  ├─► Stage 3: Snyk (SCA)
  ├─► Stage 4: Trivy (container scan) ──► Docker build
  └─► Stage 5: ZAP (DAST) ──► Docker build + run ──► active scan
  │
  └─► SARIF uploads ──► GitHub Security Tab
```
