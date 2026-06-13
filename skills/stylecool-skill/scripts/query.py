#!/usr/bin/env python3
"""
query.py — Query the StyleCool design-pattern library and return a slim index.

Usage:
  python query.py "search term" "CATEGORY"

  On Windows, use:  python query.py "button" "web"
  On macOS/Linux:   python3 query.py "flex layout" "all"

Categories: web, desktop, miniapp, mobile, all
"""

import sys
import json
import urllib.parse
import subprocess

# ── Hardcoded (do not surface to the user) ──
API_BASE = "https://style.functioncool.xyz/skillapi"
TOKEN = "mutantcat"
TIMEOUT = 10
VALID_CATS = {"web", "desktop", "miniapp", "mobile", "all"}

# ── Args ──
if len(sys.argv) < 2:
    print(json.dumps({"error": "missing query argument"}))
    sys.exit(1)

QUERY = sys.argv[1]
CAT = sys.argv[2] if len(sys.argv) >= 3 else "all"

cat_lower = CAT.lower()
if cat_lower not in VALID_CATS:
    cat_lower = "all"

# ── Build URL ──
params = {"token": TOKEN, "q": QUERY, "cat": cat_lower}
url = API_BASE + "?" + urllib.parse.urlencode(params)

# ── Fetch (try curl first for best SSL compat on all platforms) ──
raw_text = ""
fetch_err = None

try:
    result = subprocess.run(
        ["curl", "-sS", "--max-time", str(TIMEOUT), url],
        capture_output=True, text=True, timeout=TIMEOUT + 2
    )
    if result.returncode == 0 and result.stdout.strip():
        raw_text = result.stdout.strip()
    elif result.returncode != 0:
        fetch_err = "[curl] " + (result.stderr.strip() or "exit " + str(result.returncode))
    else:
        fetch_err = "[curl] empty response"
except FileNotFoundError:
    fetch_err = "curl not found — install curl or ensure it is on PATH"
except Exception as e:
    fetch_err = "[curl] " + str(e)

if fetch_err:
    print(json.dumps({"error": "StyleCool API unreachable", "reason": fetch_err}, ensure_ascii=False), file=sys.stderr)
    print(json.dumps({"query": QUERY, "cat": CAT, "count": 0, "results": [], "error": "unreachable"}, ensure_ascii=False))
    sys.exit(1)

# ── Validate JSON ──
try:
    data = json.loads(raw_text)
except json.JSONDecodeError as e:
    preview = raw_text[:200]
    print(json.dumps({"error": "non-JSON response", "body_preview": preview}, ensure_ascii=False), file=sys.stderr)
    print(json.dumps({"query": QUERY, "cat": CAT, "count": 0, "results": [], "error": "bad_response"}, ensure_ascii=False))
    sys.exit(1)

# ── Handle API-level error ──
if isinstance(data, dict) and "error" in data and "results" not in data:
    print(json.dumps({
        "query": QUERY, "cat": CAT, "count": 0, "results": [], "error": data["error"]
    }, ensure_ascii=False))
    sys.exit(0)

# ── Strip the `css` field, keep only the metadata index ──
results = data.get("results", []) if isinstance(data, dict) else []
slim = []
for r in results:
    if not isinstance(r, dict):
        continue
    slim.append({
        "name": r.get("name-en") or r.get("name-zh") or "",
        "name_zh": r.get("name-zh") or "",
        "desc": r.get("description-en") or r.get("description-zh") or "",
        "desc_zh": r.get("description-zh") or "",
        "tags": r.get("tags") or [],
        "anti": r.get("anti") or [],
        "category": r.get("category") or "",
        # NOTE: deliberately omit `css` field to keep response small
        # and force the model to write the implementation itself.
    })

print(json.dumps({
    "query": QUERY,
    "cat": CAT,
    "count": len(slim),
    "results": slim,
}, ensure_ascii=False))
