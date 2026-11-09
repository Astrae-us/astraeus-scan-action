# Astraeus Attack Surface Scan

[![Release](https://img.shields.io/github/v/tag/Astrae-us/astraeus-scan-action?sort=semver&label=release&color=1f6feb&logo=github)](https://github.com/Astrae-us/astraeus-scan-action/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-1f6feb.svg)](./LICENSE)
[![Astraeus](https://img.shields.io/badge/by-Astraeus-1f6feb)](https://astrae.us)

Scan a domain for public exposure on every push or PR, and fail the build when
new exposure appears. It checks the paths an attacker probes first — exposed
`.env` / `.git`, admin panels, debug endpoints, listable cloud buckets, and TLS
problems — and needs **no API key** (it uses the free Astraeus public scan).

## What it checks, and what it does not

This runs the free one-shot scan against **the apex domain**:

- 79 known-sensitive paths (`.env`, `.git`, admin panels, debug endpoints, …)
- SPF and DMARC
- TLS certificate validity and days to expiry
- Anonymously listable cloud buckets
- How many hosts appear in certificate transparency logs

It does **not** probe subdomains, scan ports, or fingerprint software versions.
So a green run means "nothing exposed on the apex, in what a one-shot scan can
reach" — not "nothing exposed". A `.git` directory served by `wiki.example.com`,
an open database port, or a known CVE on a service version are all outside what
this can see; every run prints that caveat so a pass is never mistaken for a
clean bill of health. Continuous monitoring across every host is what an
[account](https://astrae.us) adds.

## Quick start

```yaml
# .github/workflows/astraeus.yml
name: Attack surface
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: Astrae-us/astraeus-scan-action@v1
        with:
          domain: example.com
          fail-on: high
```

## Inputs

| Input | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `domain` | yes | — | Domain to scan. Only scan domains you own or are authorized to assess. |
| `fail-on` | no | `high` | Minimum severity that fails the build: `critical`, `high`, `medium`, `low`, or `none`. |
| `api-url` | no | `https://astrae.us/api/v1` | API base URL (override for self-hosted). |

## Outputs

| Output | Description |
|--------|-------------|
| `total-findings` | Total findings surfaced by the scan. |
| `critical` | Number of critical findings. |
| `high` | Number of high findings. |

## Examples

Gate a deploy on a clean critical result:

```yaml
- id: scan
  uses: Astrae-us/astraeus-scan-action@v1
  with:
    domain: example.com
    fail-on: critical
- run: ./deploy.sh
  if: steps.scan.outputs.critical == '0'
```

Audit mode — report without failing the build:

```yaml
- uses: Astrae-us/astraeus-scan-action@v1
  with:
    domain: example.com
    fail-on: none
```

Scan several domains with a matrix:

```yaml
strategy:
  matrix:
    domain: [example.com, api.example.com, staging.example.com]
steps:
  - uses: Astrae-us/astraeus-scan-action@v1
    with:
      domain: ${{ matrix.domain }}
```

A full workflow is in [`examples/astraeus.yml`](./examples/astraeus.yml).

## Output

Each run writes a severity table and the top findings to the job's **Step
Summary**, with links to the full report and to continuous monitoring. Findings
at or above `fail-on` exit non-zero; a transient API or network error warns and
skips, so a blip never breaks your pipeline.

## How it works

A composite action: [`scan.sh`](./scan.sh) POSTs the domain to the Astraeus
public scan API and maps the result to the step summary, outputs, and exit code.
That's the whole thing — it's short enough to read in a minute.

## Security

The action reads no repository secrets and stores no credentials; it sends only
the domain you pass. See [SECURITY.md](./SECURITY.md) for details and how to
report a vulnerability.

## About

[Astraeus](https://astrae.us) is external attack surface monitoring for small
teams: continuous discovery, exposure detection, and change alerts. This action
is the one-shot CI version — a [free account](https://astrae.us) adds continuous
scans, full evidence, and alerts across your whole surface.

## License

[MIT](./LICENSE)
