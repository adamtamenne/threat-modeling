# STRIDE Threat Analysis: oauth2-proxy

## Spoofing

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| S-1 | Session cookie | Attacker steals the session cookie (XSS, network sniffing, malware) and replays it from a different machine. The proxy doesn't tie the cookie to the original browser, so it works from anywhere. | High | Cookie flags: Secure, HttpOnly, SameSite=strict. Short expiration. Enable cookie refresh to rotate tokens. |
| S-2 | Identity headers | Attacker reaches the upstream app directly (skipping the proxy) and sends fake `X-Forwarded-User` / `X-Forwarded-Email` / `X-Forwarded-Groups` headers. The app trusts them and grants access as any user. | Critical | Network-isolate upstreams so they're only reachable through the proxy. Enable `skip_auth_strip_headers` (strips client-supplied identity headers). Enable request signing with `signature_key`. |
| S-3 | OAuth2 client | Attacker gets the OAuth2 `client_secret` (leaked config, container image, env var dump) and uses it to impersonate the proxy when exchanging codes for tokens with the IdP. | High | Store client_secret in a secrets manager. Rotate it. Scope it to minimum permissions at the IdP. |
| S-4 | Login CSRF | Attacker starts an OAuth login flow and tricks the victim into completing it. The victim ends up logged in as the attacker and might enter sensitive data into the attacker's account. | Medium | oauth2-proxy uses a CSRF cookie tied to the OAuth state parameter. Keep `cookie_csrf_expire` short (default 15m). |
| S-5 | IdP trust | If `insecure_oidc_skip_issuer_verification` is set to true, an attacker controlling any OIDC endpoint can issue tokens the proxy will accept, spoofing any user. | High | Never disable issuer verification in production. Explicitly set `oidc_issuer_url`. |

## Tampering

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| T-1 | Session cookie | If the `cookie_secret` (encryption key) is weak or leaked, an attacker can decrypt the cookie, change the user email or groups inside it, re-encrypt it, and escalate their privileges. | Critical | Use a random 32-byte cookie_secret. Store in a secrets manager. Rotate on a schedule. |
| T-2 | Redis sessions | Attacker with access to Redis modifies session data directly (change email, add admin group). Redis doesn't check integrity of stored values. | High | Require Redis AUTH. Use TLS (`rediss://`). Restrict network access to Redis. Use Redis ACLs. |
| T-3 | Configuration | Attacker modifies the proxy config (config file, env vars, K8s ConfigMap) to disable auth, add `skip_auth_routes`, or change upstreams. | Critical | Restrict write access to config. Kubernetes RBAC on ConfigMaps/Secrets. Use `--config-test` in CI/CD. Monitor for config drift. |
| T-4 | X-Forwarded headers | When behind a reverse proxy with `reverse_proxy: true`, an attacker who reaches oauth2-proxy directly (bypassing the front proxy) can forge `X-Forwarded-Proto`, `X-Forwarded-Host`, and `X-Forwarded-For` to manipulate redirects and client IP resolution. | High | Set `trusted_proxy_ips` to only the front proxy's IP. Never leave it unset (which trusts everyone). |

## Repudiation

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| R-1 | Auth events | If logs aren't centralized or can be tampered with, an attacker who hijacks a session can deny they accessed the app. No audit trail exists outside the proxy's own logs. | Medium | Ship logs to a centralized SIEM. Include correlation IDs in upstream requests. |
| R-2 | Sign-out | `/oauth2/sign_out` only clears the proxy's cookie. It doesn't revoke tokens at the IdP or kill the Redis session. A captured cookie or token may still be usable after "sign-out." | Medium | Chain sign-out to the IdP's logout endpoint. If using Redis, delete the session key on sign-out. |

## Information Disclosure

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| I-1 | Redirect URLs | When `{id_token}` is used in redirect URLs, the token shows up in browser history, server logs, and Referer headers. Anyone who can see those locations gets a valid credential. | High | Don't use `{id_token}` in redirect URLs. Use `pass_authorization_header` to send it as a header instead. |
| I-2 | /oauth2/userinfo | This endpoint returns the logged-in user's email as JSON. If it's accessible to other users or the public, it leaks PII. | Medium | Restrict to internal callers only. Disable if not needed. |
| I-3 | /metrics | Prometheus metrics expose request counts, error rates, and endpoint paths. Useful recon for an attacker. | Low | Bind `metrics_address` to an internal-only interface. |
| I-4 | Debug errors | `show_debug_on_error: true` dumps stack traces, config details, and internal state on error pages. | High | Never enable in production. |
| I-5 | cookie_secret exposure | The cookie_secret encrypts every session. If it's in source control, visible in container env, or stored in an unencrypted K8s Secret, all current and future sessions are compromised. | Critical | Secrets manager. K8s etcd encryption at rest. Never commit to git. |
| I-6 | Token forwarding | `pass_access_token` and `pass_authorization_header` forward OAuth tokens to every upstream. A compromised upstream gets tokens it can use to impersonate the user at other services. | High | Only enable for upstreams that need tokens. Run separate proxy instances for different upstreams if needed. |
| I-7 | Redis exposure | Session data in Redis includes tokens and user claims. Unauthed or unencrypted Redis exposes all active sessions. | High | Redis AUTH + TLS. Network isolation. ACLs. |

## Denial of Service

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| D-1 | Auth flow | Attacker floods `/oauth2/start`, triggering mass token exchange requests to the IdP. Can exhaust IdP rate limits and block legitimate logins. | Medium | Rate-limit auth endpoints at the load balancer. |
| D-2 | Session store | Attacker creates tons of sessions to exhaust Redis memory. Redis goes down, all users lose their sessions. | Medium | Redis `maxmemory` with eviction policy. Short cookie/session TTLs. Rate-limit new sessions. |
| D-3 | Proxy resources | High request volume forces constant cookie decryption or Redis lookups, exhausting proxy CPU/memory. | Medium | Rate-limiting load balancer. Horizontal scaling. Redis connection limits. |
| D-4 | CSRF cookies | With `cookie_csrf_per_request: true`, each parallel login flow creates a CSRF cookie. Attacker triggers many flows to fill the cookie jar. | Low | Set `cookie_csrf_per_request_limit`. |

## Elevation of Privilege

| # | Component | Threat | Risk | Mitigation |
|---|-----------|--------|------|------------|
| E-1 | Group claims | If the IdP lets users set their own groups (misconfigured SAML/OIDC), a user adds themselves to an admin group. The proxy forwards it as `X-Forwarded-Groups`, the upstream grants admin access. | High | Lock down group claim management at the IdP. Use `allowed_groups` to whitelist. Validate claims at the upstream too. |
| E-2 | skip_auth_routes | Misconfigured `skip_auth_routes` patterns let unauthenticated users hit sensitive endpoints. Path normalization differences (double slashes, encoded chars, path traversal) can make routes match when they shouldn't. | Critical | Minimize skip_auth entries. Test against encoding/traversal tricks. Use narrow patterns like `^/health$` not `/public.*`. |
| E-3 | Trusted IPs | `trusted_ips` bypasses auth for listed IPs. If an attacker spoofs their source IP via a misconfigured load balancer, they bypass auth entirely. | High | Avoid `trusted_ips`. If used, lock down `trusted_proxy_ips` so IP resolution comes from a trusted source. |
| E-4 | Bearer token bypass | `skip_jwt_bearer_tokens: true` accepts JWTs without the OAuth flow. Weak JWT validation (wrong issuer, no audience check) lets an attacker craft a JWT and skip auth. | High | If enabled, explicitly set issuer, audience, and allowed algorithms. Prefer disabling unless API clients need it. |
| E-5 | Nonce skip default | `insecure_oidc_skip_nonce` defaults to `true`. Without nonce validation, a captured ID token from one flow can be replayed in another. | Medium | Set `insecure_oidc_skip_nonce: false` explicitly. |

## Risk Summary

| Risk Level | Count | Key Threats |
|-----------|-------|------------|
| Critical | 4 | Header spoofing bypasses auth for all upstreams (S-2), cookie_secret compromise decrypts all sessions (T-1, I-5), config tampering disables auth (T-3), skip_auth_routes bypass (E-2) |
| High | 9 | Cookie replay (S-1), client secret theft (S-3), IdP trust bypass (S-5), Redis tampering (T-2), header forgery (T-4), token in URLs (I-1), token forwarded to all upstreams (I-6), Redis exposure (I-7), debug info leak (I-4), group claim manipulation (E-1), trusted IP bypass (E-3), JWT bypass (E-4) |
| Medium | 6 | Login CSRF (S-4), no audit trail (R-1), partial sign-out (R-2), userinfo leak (I-2), auth flow flood (D-1), Redis exhaustion (D-2), proxy exhaustion (D-3), nonce skip (E-5) |
| Low | 2 | Metrics recon (I-3), CSRF cookie stuffing (D-4) |
