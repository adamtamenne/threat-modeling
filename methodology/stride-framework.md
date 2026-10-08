# STRIDE Threat Modeling Framework

## Overview

STRIDE is a threat classification model developed at Microsoft. Each letter represents a category of threat that maps to a violated security property:

| Category | Violated Property | Question |
|----------|------------------|----------|
| **S**poofing | Authentication | Can an attacker pretend to be someone or something else? |
| **T**ampering | Integrity | Can an attacker modify data they shouldn't? |
| **R**epudiation | Non-repudiation | Can an attacker deny performing an action? |
| **I**nformation Disclosure | Confidentiality | Can an attacker access data they shouldn't see? |
| **D**enial of Service | Availability | Can an attacker prevent legitimate users from accessing the system? |
| **E**levation of Privilege | Authorization | Can an attacker gain capabilities they shouldn't have? |

## Process Used in This Repo

1. **Define the system** — Document architecture, components, and data stores
2. **Draw data flow diagrams** — Map how data moves between components, identify trust boundaries
3. **Enumerate threats** — Apply STRIDE to each component and data flow crossing a trust boundary
4. **Rate risk** — Assess each threat using the rating system below
5. **Map mitigations** — Identify controls that reduce or eliminate each threat

## Risk Rating System

Each threat is rated on two dimensions: **likelihood** (how probable the attack is) and **impact** (how severe the consequence is).

| Rating | Likelihood | Impact |
|--------|-----------|--------|
| **Critical** | Trivially exploitable, public tooling exists | Full system compromise, mass data breach, regulatory penalty |
| **High** | Exploitable with moderate skill, attack path is clear | Significant data loss, service outage, credential theft |
| **Medium** | Requires specific conditions or insider knowledge | Limited data exposure, partial service degradation |
| **Low** | Theoretical, requires chained exploits or physical access | Minimal impact, informational exposure |

## When to Use STRIDE

STRIDE works best for systems where you can draw a meaningful data flow diagram. It is component-oriented: you walk each element of the DFD and ask "what can go wrong here?" For threat models focused on attacker motivation or business risk, PASTA or attack trees may be more appropriate. This repo uses STRIDE because it is systematic, repeatable, and widely understood by engineering teams.
