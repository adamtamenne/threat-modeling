# STRIDE Threat Analysis: Flask Demo Application

## Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | Login endpoint | Attacker brute-forces credentials. No rate limiting, no account lockout. | High | Implement rate limiting (e.g. flask-limiter), add account lockout after N failures |
| S-2 | Session management | Attacker steals session cookie. Flask default secret key is weak or hardcoded, cookies lack Secure/HttpOnly flags. | High | Use cryptographically random SECRET_KEY from environment variable, set Secure and HttpOnly cookie flags |
| S-3 | Login endpoint | Attacker uses credentials obtained via SQL injection (see T-1). Plaintext password storage means dumped creds are immediately usable. | Critical | Hash passwords with bcrypt/argon2, parameterize queries to prevent extraction |

## Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | Search/login routes | SQL injection via string concatenation. Attacker modifies queries to extract, modify, or delete data. | Critical | Use parameterized queries (SQLAlchemy ORM or `?` placeholders) |
| T-2 | Pickle endpoint | Attacker sends crafted serialized object via base64 input. `pickle.loads()` on untrusted data allows arbitrary code execution. | Critical | Remove pickle deserialization entirely, or use JSON for data interchange |
| T-3 | SQLite database | No integrity checks on the database file. Any process in the container can read/write it. | Medium | Use a proper database engine with authentication, apply filesystem permissions |

## Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | All routes | No request logging or audit trail. Attacker actions (login attempts, data access, injections) leave no trace. | Medium | Add structured logging for authentication events and data access, ship logs to a centralized system |
| R-2 | Admin actions | No distinction between user roles. If admin functionality existed, there would be no way to attribute actions to specific users. | Low | Implement role-based access control with per-action audit logging |

## Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | Source code | Stripe API key hardcoded in `app.py`. Exposed in version control history. | Critical | Move secrets to environment variables or a secrets manager. Rotate the exposed key immediately. |
| I-2 | Error handling | Flask debug mode or default error pages may expose stack traces, file paths, and internal state to users. | High | Disable debug mode in production, implement custom error handlers |
| I-3 | Database | Passwords stored in plaintext. A database compromise (via SQLi or file access) exposes all credentials. | Critical | Hash passwords with bcrypt (work factor >= 12) |
| I-4 | HTTP responses | No security headers (Content-Security-Policy, X-Content-Type-Options, X-Frame-Options). Browser protections disabled. | Medium | Add security headers via flask-talisman or middleware |

## Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | All routes | No rate limiting. Attacker floods endpoints with requests. | Medium | Add rate limiting per IP/endpoint |
| D-2 | Pickle endpoint | Deserializing a crafted object could consume unbounded memory or CPU. | High | Remove pickle endpoint, or add input size limits and timeout |
| D-3 | SQLite | Single-writer lock. Concurrent writes block each other; a flood of write requests stalls the app. | Medium | Use PostgreSQL or MySQL for concurrent workloads |

## Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | Pickle endpoint | Arbitrary code execution via deserialization. Attacker gains code execution as the Flask process user inside the container. | Critical | Remove pickle deserialization of untrusted input |
| E-2 | Container | Flask process runs as root in the container (no USER directive in Dockerfile). Code execution escalates to container root. | High | Add `USER nonroot` to Dockerfile, run as non-root |
| E-3 | SQL injection | `ATTACH DATABASE` or SQLite-specific commands could write files to disk or access other databases if filesystem permissions allow. | Medium | Parameterize queries, restrict SQLite file permissions |

## Risk Summary

| Risk Level | Count | Key Items |
|-----------|-------|-----------|
| Critical | 5 | SQLi, pickle RCE, hardcoded secrets, plaintext passwords |
| High | 4 | Session hijacking, brute force, debug exposure, container root |
| Medium | 5 | Missing headers, no logging, DoS, DB integrity |
| Low | 1 | Role attribution |
