#!/usr/bin/env bash
# Astraeus attack-surface scan for CI. Calls the public scan API, prints a
# summary (+ a GitHub step summary), sets outputs, and exits non-zero when
# findings at/above `fail-on` are present. Never hard-fails on a transient API
# error — a flaky network shouldn't break your pipeline.
set -euo pipefail

DOMAIN="${INPUT_DOMAIN:?domain input is required}"
FAIL_ON="${INPUT_FAIL_ON:-high}"
API="${INPUT_API_URL:-https://astrae.us/api/v1}"

echo "🔭 Astraeus scanning ${DOMAIN} ..."

if ! resp="$(curl -sS --max-time 120 -X POST "${API}/tools/scan" \
      -H 'content-type: application/json' \
      -d "{\"domain\":\"${DOMAIN}\"}")"; then
  echo "::warning::Astraeus scan request failed (network/timeout); skipping without failing the build."
  exit 0
fi

ASTRAEUS_RESP="$resp" python3 - "$DOMAIN" "$FAIL_ON" <<'PY'
import json, os, sys

domain, fail_on = sys.argv[1], sys.argv[2].strip().lower()
order = ["critical", "high", "medium", "low", "info"]

try:
    d = json.loads(os.environ.get("ASTRAEUS_RESP", ""))
except Exception:
    print("::warning::Astraeus returned a non-JSON response (rate limited?); skipping.")
    sys.exit(0)

# API errors come back as {"detail": "..."}.
if not isinstance(d, dict) or "severity_counts" not in d:
    print(f"::warning::Astraeus: {d.get('detail', 'unexpected response') if isinstance(d, dict) else 'unexpected response'}; skipping.")
    sys.exit(0)

sc = d.get("severity_counts", {}) or {}
total = d.get("total_findings", 0)
summary = d.get("summary", "")
top = d.get("top_findings", []) or []

# Deep links: the shareable result page (rich findings + evidence) and a signup
# pre-filled to monitor this exact domain — so CI failures lead somewhere useful.
from urllib.parse import quote
report_url = d.get("share_url") or "https://astrae.us/tools/scan"
monitor_url = (
    "https://astrae.us/auth/login?intent=start&utm_source=github-action&next="
    + quote(f"/dashboard/domains?add={domain}", safe="")
)

print(f"\nResult for {domain}: {summary}")
print("Severity: " + ", ".join(f"{s}={sc.get(s, 0)}" for s in order))
for f in top:
    print(f"  - [{f.get('severity','')}] {f.get('title','')}")
print(f"Full report: {report_url}")

# GitHub outputs
out = os.environ.get("GITHUB_OUTPUT")
if out:
    with open(out, "a") as fh:
        fh.write(f"total_findings={total}\n")
        fh.write(f"critical={sc.get('critical', 0)}\n")
        fh.write(f"high={sc.get('high', 0)}\n")

# GitHub step summary
step = os.environ.get("GITHUB_STEP_SUMMARY")
if step:
    with open(step, "a") as fh:
        fh.write(f"## 🔭 Astraeus scan: `{domain}`\n\n{summary}\n\n")
        fh.write("| Severity | Count |\n|---|---:|\n")
        for s in order:
            fh.write(f"| {s} | {sc.get(s, 0)} |\n")
        if top:
            fh.write("\n**Top findings**\n\n")
            for f in top:
                fh.write(f"- **{f.get('severity','')}** — {f.get('title','')}\n")
        fh.write(
            f"\n[See the full report →]({report_url}) &nbsp;·&nbsp; "
            f"[Monitor `{domain}` continuously →]({monitor_url})\n"
        )

if fail_on == "none":
    sys.exit(0)

thresh = order.index(fail_on) if fail_on in order else 1  # default: high
bad = sum(sc.get(s, 0) for s in order[: thresh + 1])
if bad > 0:
    print(f"\n::error::{bad} finding(s) at or above '{fail_on}' — failing the build.")
    sys.exit(1)
print(f"\n✅ No findings at or above '{fail_on}'.")
PY
