# Data Flow Diagram: Flask Demo Application

## Level 0 — Context Diagram

```mermaid
flowchart LR
    User([User / Browser])
    App[Flask Application]
    DB[(SQLite Database)]

    User -->|HTTP requests\nform data, search queries| App
    App -->|HTML responses\nuser data rendered inline| User
    App -->|SQL queries\nraw string concatenation| DB
    DB -->|Query results\nuser records, credentials| App
```

## Level 1 — Component Diagram with Trust Boundaries

```mermaid
flowchart TB
    subgraph TB1["Trust Boundary: Internet"]
        User([User / Browser])
    end

    subgraph TB2["Trust Boundary: Container"]
        subgraph AppLayer["Application Layer"]
            Routes[Route Handlers]
            Templates[Jinja2 Templates]
            Pickle[Pickle Deserializer]
        end

        subgraph DataLayer["Data Layer"]
            DB[(SQLite DB)]
            Config[Hardcoded Config\nAPI keys, secrets]
        end

        Routes -->|renders user input\nno escaping| Templates
        Routes -->|string-formatted SQL\nno parameterization| DB
        Routes -->|deserializes untrusted\nbase64 input| Pickle
        Routes -->|reads secrets at runtime| Config
        DB -->|query results| Routes
    end

    User -->|HTTP POST\nlogin credentials| Routes
    User -->|HTTP GET\nsearch query in URL param| Routes
    Templates -->|HTML with reflected\nuser input| User
```

## Trust Boundaries

| Boundary | What It Separates | Key Concern |
|----------|------------------|-------------|
| Internet / Container | Untrusted user input enters the application | All input crosses this boundary unsanitized |
| Application / Data Layer | App logic accesses stored data and secrets | SQL queries built from raw user input; secrets readable in source |

## Data Flows Crossing Trust Boundaries

| # | Flow | Source | Destination | Data | Concern |
|---|------|--------|-------------|------|---------|
| DF-1 | Login request | Browser | Route handler | Username + plaintext password | No TLS enforcement, credentials in cleartext |
| DF-2 | Search query | Browser | Route handler | Arbitrary user string | Passed directly into SQL and HTML |
| DF-3 | HTML response | Template engine | Browser | User data including reflected input | XSS payload delivered to victim |
| DF-4 | SQL query | Route handler | SQLite | String-concatenated query | Injection point |
| DF-5 | Deserialization input | Browser | Pickle handler | Base64-encoded serialized object | Arbitrary code execution |
