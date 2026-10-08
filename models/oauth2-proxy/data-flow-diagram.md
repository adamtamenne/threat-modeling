# Data Flow Diagrams: oauth2-proxy

## Level 0 — Context Diagram

```mermaid
flowchart LR
    User([End User / Browser])
    Proxy[oauth2-proxy]
    IdP([OAuth2 / OIDC Provider])
    Upstream([Upstream Application])
    Redis([Redis Session Store])

    User -->|HTTPS requests| Proxy
    Proxy -->|Auth redirect,\ncallback| IdP
    IdP -->|Authorization code,\ntokens| Proxy
    Proxy -->|Authenticated request\n+ identity headers| Upstream
    Proxy <-->|Session read/write| Redis
    Proxy -->|Authenticated response| User
```

## Level 1 — Detailed Flow with Trust Boundaries

```mermaid
flowchart TB
    subgraph TB_Untrusted["Trust Boundary: Untrusted (End User)"]
        Browser([User Browser])
        Cookie[Session Cookie\nin Browser]
    end

    subgraph TB_Edge["Trust Boundary: Edge / Authentication Proxy"]
        ProxyCore[Reverse Proxy Core]
        OAuthClient[OAuth2/OIDC Client]
        SessionMgr[Session Manager]
        HeaderInjector[Header Injector]
        EndpointHandler[Endpoint Handler\n/sign_in /callback\n/auth /sign_out\n/userinfo]
        Config[Configuration\nclient_secret\ncookie_secret\nprovider settings]
        CSRFHandler[CSRF Token Handler]
    end

    subgraph TB_Internal["Trust Boundary: Trusted Internal Network"]
        Upstream1([Upstream Service A])
        Upstream2([Upstream Service B])
    end

    subgraph TB_External["Trust Boundary: External Services"]
        IdP([Identity Provider\nGoogle / Entra ID /\nGitHub / Okta])
        RedisStore([Redis\nSession Store])
    end

    Browser -->|"1. HTTPS request"| ProxyCore
    ProxyCore -->|"2a. No valid session"| EndpointHandler
    EndpointHandler -->|"2b. Redirect to /oauth2/start"| Browser
    Browser -->|"3. Follow redirect to IdP"| IdP
    IdP -->|"4. User authenticates,\nIdP redirects with auth code"| Browser
    Browser -->|"5. GET /oauth2/callback?code=..."| EndpointHandler
    EndpointHandler -->|"6. Exchange code for tokens"| OAuthClient
    OAuthClient -->|"7. Token request\n(client_id, client_secret, code)"| IdP
    IdP -->|"8. Access token, ID token,\nrefresh token"| OAuthClient
    OAuthClient -->|"9. Tokens + user claims"| SessionMgr
    SessionMgr -->|"10a. Store session"| RedisStore
    SessionMgr -->|"10b. Set encrypted\nsession cookie"| Cookie
    CSRFHandler -->|"CSRF cookie\nset/validate"| Cookie
    Config -->|"Encryption key,\nclient credentials"| OAuthClient
    Config -->|"Cookie secret"| SessionMgr

    ProxyCore -->|"11. Valid session exists"| HeaderInjector
    HeaderInjector -->|"12. X-Forwarded-User\nX-Forwarded-Email\nX-Forwarded-Groups\nAuthorization: Bearer"| Upstream1
    HeaderInjector -->|"12. Identity headers"| Upstream2

    SessionMgr -->|"Refresh token grant"| IdP
```

## Trust Boundaries

| Boundary | What's Inside | Why It's a Boundary |
|----------|--------------|-------------------|
| Untrusted (End User) | Browser, session cookie | You control nothing here. Cookie can be stolen, browser can be compromised. |
| Edge (Auth Proxy) | Proxy core, OAuth client, session manager, header injector, config | This is the gate. It's internet-facing and makes the auth decision for everything behind it. If it's misconfigured, auth is bypassed for all upstreams. |
| Trusted Internal | Upstream apps | These trust the identity headers blindly. They have no way to verify them on their own. |
| External Services | Identity provider (Google, Okta, etc.), Redis | Outside your control. If the IdP is compromised, your auth is compromised. If Redis is breached, all sessions are exposed. |

## Critical Data Flows

| # | What Happens | What Data Moves | Boundary Crossing |
|---|-------------|----------------|-------------------|
| DF-1 | User sends a request | HTTP request + session cookie | Untrusted → Edge |
| DF-2 | Proxy redirects to login | Redirect URL with state/nonce | Edge → Untrusted |
| DF-3 | User logs in at the IdP | User's credentials (handled by IdP) | Untrusted → External |
| DF-4 | IdP sends auth code back | Authorization code via browser redirect | External → Untrusted → Edge |
| DF-5 | Proxy exchanges code for tokens | Client ID, client secret, auth code | Edge → External |
| DF-6 | IdP returns tokens | Access token, ID token, refresh token | External → Edge |
| DF-7 | Proxy stores session in Redis | Session data with tokens and user claims | Edge → External |
| DF-8 | Proxy sets session cookie | Encrypted cookie with session data | Edge → Untrusted |
| DF-9 | Proxy forwards to upstream with headers | X-Forwarded-User, Email, Groups, Authorization | Edge → Internal |
| DF-10 | Proxy refreshes expired tokens | Refresh token | Edge → External |
| DF-11 | /userinfo returns user email | Email address as JSON | Edge → Untrusted |
| DF-12 | Sign-out with redirect | Redirect URL via `rd` parameter | Edge → Untrusted |
