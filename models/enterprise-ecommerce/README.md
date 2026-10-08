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
