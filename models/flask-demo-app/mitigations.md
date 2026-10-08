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
