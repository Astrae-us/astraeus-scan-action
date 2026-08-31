# Astraeus Attack Surface Scan — GitHub Action

Scan a domain for public exposure on every push or PR, and fail the build when
new exposure appears. Catches the classics an attacker checks first: exposed
`.env` / `.git`, admin panels, debug endpoints, listable buckets, and TLS
problems.

No API key required — it uses the free public scan.

## Usage

```yaml
name: Attack surface
on:
  push:
  schedule:
    - cron: '0 6 * * *'   # also run daily
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: Astrae-us/astraeus-scan-action@v1
        with:
          domain: example.com   # a domain you own / are authorized to assess
          fail-on: high         # critical | high | medium | low | none
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `domain` | — (required) | Domain to scan. Only scan domains you own or are authorized to assess. |
| `fail-on` | `high` | Minimum severity that fails the build (`critical`/`high`/`medium`/`low`/`none`). |
| `api-url` | `https://astrae.us/api/v1` | API base (override for self-hosted). |

## Outputs

| Output | Description |
|--------|-------------|
| `total-findings` | Total findings surfaced. |
| `critical` / `high` | Count per severity. |

Each run writes a summary table to the job's **Step Summary**. A transient API
error never fails your pipeline (it warns and skips). The public scan is a
one-shot teaser; sign up at [astrae.us](https://astrae.us) for continuous
monitoring, full evidence, and change alerts across your whole surface.

---

**Publishing (maintainer):** this action lives at `integrations/github-action/`
in the main repo. To publish to the GitHub Marketplace, push this directory to
`github.com/Astrae-us/astraeus-scan-action`, tag it `v1`, and click "Publish
this Action" on the release. Consumers then reference
`Astrae-us/astraeus-scan-action@v1`.
