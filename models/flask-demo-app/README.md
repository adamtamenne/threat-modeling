# Threat Model: Flask Demo Application

**System:** Intentionally vulnerable Python/Flask web application
**Repo:** [devsecops-pipeline-demo](https://github.com/adamtamenne/devsecops-pipeline-demo)
**Date:** October 2026
**Methodology:** STRIDE

## System Overview

A deliberately insecure Flask application built to demonstrate security scanning tools. The app exposes common OWASP Top 10 vulnerabilities including SQL injection, reflected XSS, insecure deserialization, and hardcoded credentials. It runs as a single Docker container serving HTTP on port 5000.

### Components

| Component | Technology | Description |
|-----------|-----------|-------------|
| Web Server | Flask (Python 3.11) | Serves HTML pages and handles form submissions |
| Database | SQLite | Stores user credentials and application data |
| Container Runtime | Docker | Packages the app with a Python base image |
| Dependencies | pip (requirements.txt) | Pinned to intentionally vulnerable versions (Flask 2.0.1, Jinja2 3.0.1, Werkzeug 2.0.1) |

### Data Classification

| Data Type | Classification | Storage |
|-----------|---------------|---------|
| User credentials | Sensitive | SQLite (plaintext passwords) |
| API keys | Secret | Hardcoded in source (Stripe key) |
| Session tokens | Sensitive | Flask default cookie-based sessions |
| User input (search, forms) | Untrusted | Rendered directly into HTML responses |

### Intentional Vulnerabilities

This app is insecure by design. The threat model documents what would be found in a real assessment, making it useful as a reference for understanding why each vulnerability matters and what controls would fix it.
