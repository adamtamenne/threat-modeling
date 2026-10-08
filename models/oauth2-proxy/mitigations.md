# Mitigations: oauth2-proxy

Controls grouped by defense area. Each mitigation references the threat IDs it addresses.

## Area 1: Session Security

### M-1: Harden session cookies
**Addresses:** S-1, I-1
**Controls:** Use secure cookie flags and shorten the session lifetime.

```yaml
cookie_secure = true           # Only send over HTTPS (default)
cookie_httponly = true          # No JavaScript access (default)
cookie_samesite = "strict"     # Block cross-site sends
cookie_name = "__Host-oauth2-proxy"  # Browser enforces Secure + no Domain + Path=/
cookie_expire = "4h"           # Default 168h is too long
cookie_refresh = "1h"          # Rotate tokens hourly
```

### M-2: Use a strong cookie secret
**Addresses:** T-1, I-5
**Controls:** The cookie_secret encrypts all sessions. Use a random 32-byte value. Never commit it to git or pass it as a CLI flag.

```bash
# Generate a 32-byte secret
python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
```

Store in a secrets manager (Vault, AWS Secrets Manager, K8s External Secrets Operator). Use `cookie_secret_file` to load from a file instead of an env var. Rotate on a schedule.

### M-3: Secure Redis
**Addresses:** T-2, I-7, D-2
**Controls:** Require auth, encrypt the connection, restrict access.

```yaml
session_store_type = "redis"
redis_connection_url = "rediss://:<password>@redis-host:6380"  # rediss:// = TLS
```

Set Redis `maxmemory` with an eviction policy. Use ACLs. Deploy in a private subnet or use K8s NetworkPolicy.

## Area 2: Identity Header Protection

### M-4: Strip incoming identity headers
**Addresses:** S-2
**Controls:** Verify `skip_auth_strip_headers` is `true` (default). Without this, a client can send their own `X-Forwarded-User` headers and the proxy passes them through.

### M-5: Network-isolate upstreams
**Addresses:** S-2, I-6
**Controls:** Upstreams should only be reachable through the proxy. In K8s, use NetworkPolicy. On VMs, bind upstreams to localhost.

### M-6: Scope token forwarding
**Addresses:** I-6
**Controls:** `pass_access_token` and `pass_authorization_header` send tokens to every upstream. Run separate proxy instances for upstreams that need tokens vs. those that don't.

### M-7: Enable request signing
**Addresses:** S-2
**Controls:** `signature_key` adds a cryptographic signature to each upstream request. The upstream can verify the request actually came through the proxy.

```yaml
signature_key = "sha256:your-signing-key-here"
```

This is the only way to cryptographically prove a request went through the gate.

## Area 3: OAuth2/OIDC Hardening

### M-8: Protect the client secret
**Addresses:** S-3
**Controls:** Secrets manager. Short-lived credentials where the IdP supports them. Minimum-scope client at the IdP.

### M-9: Enforce OIDC validation
**Addresses:** S-5, E-4, E-5
**Controls:** Don't disable security checks.

```yaml
insecure_oidc_skip_issuer_verification = false   # Never disable
insecure_oidc_allow_unverified_email = false      # Never disable
insecure_oidc_skip_nonce = false                  # Override the insecure default

oidc_issuer_url = "https://accounts.google.com"   # Pin the issuer
oidc_audiences = "your-client-id"                  # Restrict audience
```

### M-10: Restrict post-login redirects
**Addresses:** S-4
**Controls:** Without `whitelist_domains`, the proxy can redirect to any URL after login, enabling phishing.

```yaml
whitelist_domains = [".yourdomain.com"]
```

## Area 4: Proxy Hardening

### M-11: Lock down trusted proxies
**Addresses:** T-4, E-3
**Controls:** When behind a reverse proxy, explicitly set which IPs can send `X-Forwarded-*` headers. Leaving `trusted_proxy_ips` unset trusts everyone.

```yaml
reverse_proxy = true
trusted_proxy_ips = ["10.0.0.5"]
```

### M-12: Minimize skip-auth routes
**Addresses:** E-2
**Controls:** Use narrow, exact patterns. The proxy blocks `..` and double slashes, but test your patterns anyway.

```yaml
# Too broad
skip_auth_routes = ["/public.*"]

# Better
skip_auth_routes = ["^/health$", "^/ready$"]
```

### M-13: Protect configuration
**Addresses:** T-3
**Controls:** K8s RBAC on ConfigMaps/Secrets. Run `--config-test` in CI/CD. Monitor for changes that add skip_auth_routes or disable TLS verification.

### M-14: Disable debug in production
**Addresses:** I-4
**Controls:** Never set `show_debug_on_error = true` in production.

## Area 5: Endpoint Protection

### M-15: Restrict internal endpoints
**Addresses:** I-2, I-3, D-1
**Controls:** `/metrics`, `/oauth2/userinfo`, `/ping`, `/ready` should not be public.

```yaml
metrics_address = "127.0.0.1:9090"
```

Rate-limit `/oauth2/start` and `/oauth2/callback` at the load balancer.

### M-16: Don't put tokens in URLs
**Addresses:** I-1
**Controls:** Don't use `{id_token}` in redirect URLs. Tokens in URLs leak to browser history, logs, and Referer headers. Use `pass_authorization_header` instead.

## Area 6: Upstream Claim Validation

### M-17: Validate claims at the IdP
**Addresses:** E-1
**Controls:** Lock down who can modify group claims at the IdP. Use `allowed_groups` at the proxy. Validate claims at the upstream too when possible.

```yaml
allowed_groups = ["engineering", "security"]
```

### M-18: Chain sign-out to the IdP
**Addresses:** R-2
**Controls:** `/oauth2/sign_out` only kills the proxy cookie. Redirect to the IdP's logout to actually end the session.

## Area 7: Availability and Auditability

### M-19: Rate-limit and scale
**Addresses:** D-1, D-2, D-3, D-4
**Controls:** Rate-limiting load balancer. Horizontal scaling. Redis connection limits. Set `cookie_csrf_per_request_limit`.

### M-20: Centralize logging
**Addresses:** R-1
**Controls:** Ship logs to a SIEM. Include correlation IDs. Use structured logging.

## Control Coverage Matrix

| Threat ID | Mitigation(s) | Area |
|-----------|--------------|------|
| S-1 | M-1 | Session |
| S-2 | M-4, M-5, M-7 | Headers |
| S-3 | M-8 | OAuth2/OIDC |
| S-4 | M-10 | OAuth2/OIDC |
| S-5 | M-9 | OAuth2/OIDC |
| T-1 | M-2 | Session |
| T-2 | M-3 | Session |
| T-3 | M-13 | Proxy |
| T-4 | M-11 | Proxy |
| R-1 | M-20 | Auditability |
| R-2 | M-18 | Claims |
| I-1 | M-1, M-16 | Session, Endpoints |
| I-2 | M-15 | Endpoints |
| I-3 | M-15 | Endpoints |
| I-4 | M-14 | Proxy |
| I-5 | M-2 | Session |
| I-6 | M-5, M-6 | Headers |
| I-7 | M-3 | Session |
| D-1 | M-15, M-19 | Endpoints |
| D-2 | M-3, M-19 | Session |
| D-3 | M-19 | Availability |
| D-4 | M-19 | Availability |
| E-1 | M-17 | Claims |
| E-2 | M-12 | Proxy |
| E-3 | M-11 | Proxy |
| E-4 | M-9 | OAuth2/OIDC |
| E-5 | M-9 | OAuth2/OIDC |
