# Security Policy

## Reporting a vulnerability

Report security issues privately to **security@astrae.us** — please do **not**
open a public issue.

Include where relevant:
- A description of the issue and its impact
- Steps to reproduce (a minimal workflow snippet is ideal)
- The action version / commit SHA you're using

We aim to acknowledge within **2 business days** and will keep you updated as we
work on a fix. Please give us a reasonable window to remediate before public
disclosure. We're happy to credit you once a fix ships.

See also: https://astrae.us/security · https://astrae.us/.well-known/security.txt

## Supported versions

| Version | Supported |
|---------|-----------|
| `v1` (latest `v1.x.x`) | ✅ |
| older / unreleased | ❌ |

Security fixes land on the newest `v1.x.x` release, and the floating `v1` tag is
moved to point at it.

## What this action does with your pipeline

This is a **composite action** — the only code it runs is [`scan.sh`](./scan.sh),
which is short and auditable. Specifically, it:

- Sends **only the `domain` you pass in** to the Astraeus public scan API over
  HTTPS (`https://astrae.us/api/v1`, overridable via `api-url`).
- Requires **no API key or secrets**, and reads **no repository secrets, source
  code, or environment** beyond its declared inputs.
- Stores and transmits **no credentials**, and writes only a findings summary to
  the job's Step Summary and step outputs.
- Never fails your build on a transient API/network error — it warns and skips.

## Using it safely

- **Pin to a version** you trust — a release tag (`@v1`) or, for the strongest
  supply-chain guarantee, a full commit SHA (`Astrae-us/astraeus-scan-action@<sha>`).
- Only scan **domains you own or are authorized to assess**.
- Review [`action.yml`](./action.yml) and [`scan.sh`](./scan.sh) before adopting —
  they're intentionally small.
