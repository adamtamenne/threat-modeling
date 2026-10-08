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
