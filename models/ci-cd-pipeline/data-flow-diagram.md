# Data Flow Diagrams: GitHub Actions DevSecOps Pipeline

## Level 0 — Context Diagram

```mermaid
flowchart LR
    Dev([Developer])
    Pipeline[DevSecOps Pipeline]
    GitHub([GitHub Platform])
    Snyk([Snyk API])
    Registry([Container Registry])

    Dev -->|Push code,\nopen PR| GitHub
    GitHub -->|Trigger workflow| Pipeline
    Pipeline -->|Upload SARIF,\nartifacts| GitHub
    Pipeline -->|Dependency\nvulnerability check| Snyk
    Pipeline -->|Pull base images| Registry
    GitHub -->|Scan results,\nalerts| Dev
```

## Level 1 — Pipeline Detail with Trust Boundaries

```mermaid
flowchart TB
    subgraph TB_Dev["Trust Boundary: Developer Workstation"]
        Dev([Developer])
        LocalGit[Local Git Repo]
    end

    subgraph TB_GitHub["Trust Boundary: GitHub Platform"]
        Repo[Source Repository]
        Secrets[GitHub Secrets]
        SecurityTab[Security Tab\nCode Scanning]
        ArtifactStore[Actions Artifacts]
        ActionsEngine[Actions Workflow Engine]
    end

    subgraph TB_Runner["Trust Boundary: Ephemeral Runner (ubuntu-latest)"]
        Checkout[actions/checkout]

        subgraph Stage1["Stage 1"]
            Gitleaks[Gitleaks Scanner]
        end
        subgraph Stage2["Stage 2"]
            Semgrep[Semgrep Scanner]
        end
        subgraph Stage3["Stage 3"]
            SnykCLI[Snyk CLI]
        end
        subgraph Stage4["Stage 4"]
            DockerBuild4[Docker Build]
            Trivy[Trivy Scanner]
        end
        subgraph Stage5["Stage 5"]
            DockerBuild5[Docker Build + Run]
            ZAP[OWASP ZAP]
        end

        SARIFUpload[SARIF Upload Action]
    end

    subgraph TB_External["Trust Boundary: Third-Party Services"]
        SnykAPI([Snyk Vulnerability DB])
        DockerHub([Docker Hub / Registry])
        SemgrepRegistry([Semgrep Rules Registry])
        GitHubMarketplace([Actions Marketplace])
    end

    Dev -->|git push| LocalGit
    LocalGit -->|Push over HTTPS| Repo
    Repo -->|Webhook trigger| ActionsEngine
    ActionsEngine -->|Provision runner,\ninject secrets| Checkout
    Secrets -->|SNYK_TOKEN,\nGITHUB_TOKEN| Checkout

    Checkout -->|Source code| Gitleaks
    Checkout -->|Source code| Semgrep
    Checkout -->|requirements.txt| SnykCLI
    Checkout -->|Dockerfile + source| DockerBuild4
    Checkout -->|Dockerfile + source| DockerBuild5

    Semgrep -->|Fetch rules| SemgrepRegistry
    SnykCLI -->|API call with token| SnykAPI
    DockerBuild4 -->|Pull base image| DockerHub
    DockerBuild5 -->|Pull base image| DockerHub
    DockerBuild4 -->|Built image| Trivy
    DockerBuild5 -->|Running container| ZAP

    Gitleaks -->|SARIF| SARIFUpload
    Semgrep -->|SARIF| SARIFUpload
    SnykCLI -->|SARIF| SARIFUpload
    Trivy -->|SARIF| SARIFUpload
    ZAP -->|SARIF| SARIFUpload

    SARIFUpload -->|Upload results| SecurityTab
    SARIFUpload -->|Upload reports| ArtifactStore
    SecurityTab -->|Alerts| Dev
```

## Trust Boundaries

| Boundary | Components Inside | Rationale |
|----------|------------------|-----------|
| Developer Workstation | Local git repo, IDE, credentials | Trusted but outside platform control. Compromised workstation can push malicious code or steal credentials. |
| GitHub Platform | Repository, Secrets store, Actions engine, Security tab, Artifacts | Managed SaaS. Trust depends on GitHub's security posture and the org's configuration (branch protections, secret scoping). |
| Ephemeral Runner | Checkout action, all five scanner stages, SARIF upload | Provisioned per-job and destroyed after. Shares the runner image with other GitHub users. Code and third-party actions execute here with access to injected secrets. |
| Third-Party Services | Snyk API, Docker Hub, Semgrep rules registry, Actions Marketplace | External services accessed over HTTPS. Supply chain risk: a compromised action, base image, or rule set can inject malicious code into the pipeline. |

## Critical Data Flows

| # | Flow | Source | Destination | Data | Trust Boundary Crossing |
|---|------|--------|-------------|------|------------------------|
| DF-1 | Code push | Developer workstation | GitHub repository | Source code, Dockerfile, workflow YAML | Dev → GitHub |
| DF-2 | Runner provisioning | GitHub Actions engine | Ephemeral runner | Runner image, environment variables, secrets | GitHub → Runner |
| DF-3 | Code checkout | GitHub repository | Runner filesystem | Full repository contents | GitHub → Runner |
| DF-4 | Dependency check | Snyk CLI on runner | Snyk API | requirements.txt contents, SNYK_TOKEN | Runner → External |
| DF-5 | Base image pull | Docker daemon on runner | Docker Hub | Container base image layers | External → Runner |
| DF-6 | Rule fetch | Semgrep on runner | Semgrep registry | Scanning rule definitions | External → Runner |
| DF-7 | SARIF upload | Scanner stages on runner | GitHub Security tab | Scan results (file paths, line numbers, findings) | Runner → GitHub |
| DF-8 | Artifact upload | Scanner stages on runner | GitHub Artifacts | Full scan reports (HTML, JSON) | Runner → GitHub |
| DF-9 | Action resolution | Workflow YAML | Actions Marketplace / repos | Third-party action code | External → Runner |
