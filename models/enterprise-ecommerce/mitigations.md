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
