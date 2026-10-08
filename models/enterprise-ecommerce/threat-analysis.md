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
