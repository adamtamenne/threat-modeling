# Mitigations: GitHub Actions DevSecOps Pipeline

Controls grouped by defense area. Each mitigation references the threat IDs it addresses.

## Area 1: Supply Chain Integrity

### M-1: Pin actions to commit SHAs
**Addresses:** S-2, E-2
**Controls:** Reference every third-party action by its full commit SHA, not a mutable tag. Audit the pinned commit's source before adoption. Fork critical actions into the organization for an additional layer of control.

```yaml
# Vulnerable — tag can be moved to point at a backdoored commit
- uses: actions/checkout@v4

# Fixed — immutable reference
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

### M-2: Pin base images by digest
**Addresses:** S-4
**Controls:** Reference Docker base images by digest rather than mutable tags. Maintain a private registry mirror with image scanning and signature verification.

```dockerfile
# Vulnerable — tag can be overwritten
FROM python:3.11-slim

# Fixed — content-addressable
FROM python:3.11-slim@sha256:abc123...
```

### M-3: Dependency change review
**Addresses:** T-3
**Controls:** Enable Dependabot or Renovate to automate dependency updates with vulnerability context. Require PR reviews for any change to `requirements.txt`, `package.json`, or lockfiles. Cross-reference Snyk, OSV, and GitHub Advisory databases.

## Area 2: Workflow Hardening

### M-4: Protect workflow files with CODEOWNERS and branch protection
**Addresses:** T-1
**Controls:** Add `.github/workflows/` to a CODEOWNERS file requiring security team approval. Enable branch protection on the default branch: require PR reviews, disallow direct pushes, require status checks to pass.

```
# .github/CODEOWNERS
.github/workflows/ @org/security-team
```

### M-5: Minimize GITHUB_TOKEN permissions
**Addresses:** E-1
**Controls:** Set explicit `permissions` at the workflow and job level. Grant only what each job needs — typically `contents: read` and `security-events: write` for a scanning pipeline. Never use the default (often `write-all` for private repos).

```yaml
permissions:
  contents: read
  security-events: write
```

### M-6: Prevent workflow injection
**Addresses:** E-4
**Controls:** Never interpolate event-controlled input (`github.event.pull_request.title`, `github.event.issue.body`, etc.) directly in `run:` blocks. Pass untrusted data through environment variables, which are not subject to shell injection.

```yaml
# Vulnerable
- run: echo "PR title is ${{ github.event.pull_request.title }}"

# Fixed — environment variable is not interpreted as shell code
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "PR title is $PR_TITLE"
```

### M-7: Secure fork PR handling
**Addresses:** I-3
**Controls:** Use `pull_request` trigger (not `pull_request_target`) for workflows that run untrusted code. If `pull_request_target` is unavoidable, never checkout the fork's code in the same job that has access to secrets. Use a two-job workflow: one job to check out and build the fork code without secrets, a second job to process results with secrets.

## Area 3: Secrets Protection

### M-8: Prevent secret leakage in logs
**Addresses:** I-1
**Controls:** Never `echo`, `print`, or log any secret or value derived from a secret. Use `::add-mask::` for dynamically generated sensitive values. Periodically review workflow logs for accidental exposure. Treat all runner logs as potentially sensitive.

```yaml
- run: |
    # Mask a derived value
    DERIVED_TOKEN=$(echo "$SNYK_TOKEN" | base64)
    echo "::add-mask::$DERIVED_TOKEN"
```

### M-9: Rotate and scope third-party tokens
**Addresses:** S-3
**Controls:** Rotate SNYK_TOKEN and any other third-party API keys on a defined schedule (e.g. every 90 days). Scope tokens to the minimum permissions needed (read-only vulnerability checks, not org admin). Monitor third-party service audit logs for anomalous usage.

### M-10: Restrict secrets access
**Addresses:** R-3
**Controls:** Scope secrets to specific repositories or environments rather than the entire org. Use environment protection rules to require manual approval for jobs that access production-level secrets. Audit GitHub's org-level audit log for secrets management events.

## Area 4: Runner Security

### M-11: Use ephemeral runners
**Addresses:** E-3, I-4
**Controls:** Use GitHub-hosted runners (ephemeral by default). If self-hosted runners are required, configure them as ephemeral (`--ephemeral` flag) so each job gets a clean instance. Run self-hosted runners inside containers or VMs that are destroyed after each job.

### M-12: Set resource limits on jobs
**Addresses:** D-2
**Controls:** Set `timeout-minutes` on every job and on long-running steps (ZAP scans, large image builds). Limit Docker image size where practical. Configure scanner-specific timeouts (ZAP `cmd_options: -T 300`, Trivy `--timeout`).

```yaml
jobs:
  container-scan:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - name: Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: image
          timeout: 10m
```

### M-13: Dockerfile linting
**Addresses:** T-4
**Controls:** Add a hadolint step that runs before the Docker build. Flag `curl | sh` patterns, `RUN` commands that download external scripts, and use of `--privileged`. Review Dockerfile changes in PRs with the same rigor as application code.

## Area 5: Results Integrity and Auditability

### M-14: Protect scan results
**Addresses:** T-2, I-2
**Controls:** Validate SARIF schema before upload. Compare finding counts against the previous run and alert on significant decreases. Keep the repository private or restrict artifact download permissions. Set artifact retention to the minimum useful period.

### M-15: Signed commits
**Addresses:** R-1
**Controls:** Require GPG or SSH signed commits via branch protection. This creates a non-repudiable link between the developer identity and the code that triggered the pipeline run.

### M-16: Alert dismissal governance
**Addresses:** R-2
**Controls:** Require a reason when dismissing code scanning alerts. Restrict alert dismissal to the security team via GitHub's code scanning alert permissions. Audit dismissed alerts on a regular cadence.

## Area 6: Availability

### M-17: Pipeline trigger controls
**Addresses:** D-1, D-4
**Controls:** Use `concurrency` groups to cancel superseded runs. Filter triggers with `paths` and `branches` so irrelevant changes don't consume minutes. Set PR labels or environment gates for expensive scan stages.

```yaml
concurrency:
  group: security-pipeline-${{ github.ref }}
  cancel-in-progress: true

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

### M-18: Semgrep rule integrity
**Addresses:** T-5
**Controls:** If using custom rules, store them in a separate repository with restricted write access and code review. Pin the `--config` reference to a specific commit or release tag. Diff custom rules against baseline on every change.

## Control Coverage Matrix

| Threat ID | Mitigation(s) | Area |
|-----------|--------------|------|
| S-1 | (GitHub account security — org policy) | — |
| S-2 | M-1 | Supply Chain |
| S-3 | M-9 | Secrets |
| S-4 | M-2 | Supply Chain |
| T-1 | M-4 | Workflow |
| T-2 | M-14 | Results |
| T-3 | M-3 | Supply Chain |
| T-4 | M-13 | Runner |
| T-5 | M-18 | Availability |
| R-1 | M-15 | Results |
| R-2 | M-16 | Results |
| R-3 | M-10 | Secrets |
| I-1 | M-8 | Secrets |
| I-2 | M-14 | Results |
| I-3 | M-7 | Workflow |
| I-4 | M-11 | Runner |
| I-5 | (Operational — structured error handling) | — |
| D-1 | M-17 | Availability |
| D-2 | M-12 | Runner |
| D-3 | (Operational — rate monitoring) | — |
| D-4 | M-17 | Availability |
| E-1 | M-5 | Workflow |
| E-2 | M-1 | Supply Chain |
| E-3 | M-11 | Runner |
| E-4 | M-6 | Workflow |

Note: S-1 (GitHub credential compromise), I-5 (error output leakage), and D-3 (Snyk rate limits) are addressed by organizational policies and operational practices rather than pipeline-specific technical controls. They are included in the threat analysis for completeness and should be covered by the organization's broader security program.
