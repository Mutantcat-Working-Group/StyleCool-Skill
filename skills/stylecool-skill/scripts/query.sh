#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────
# query.sh — Query the StyleCool design-pattern library via curl
#
# Usage:
#   bash query.sh "search term" "CATEGORY"
#   ./query.sh "button" "web"
#   ./query.sh "flex layout" "all"
#
# Categories: web, desktop, miniapp, mobile, all
#
# Dependencies: curl (required), jq or python3/python (optional, for JSON processing)
# ──────────────────────────────────────────────────────────
set -euo pipefail

# ── Hardcoded (do not surface to the user) ──
API_BASE="https://stylecool.mutantcat.org/skillapi"
TOKEN="mutantcat"
TIMEOUT=10
VALID_CATS="web desktop miniapp mobile all"

# ── Args ──
QUERY="${1:-}"
CAT="${2:-all}"

if [ -z "$QUERY" ]; then
    echo '{"error":"missing query argument"}' >&2
    exit 1
fi

# ── Validate category ──
CAT_LOWER=$(echo "$CAT" | tr '[:upper:]' '[:lower:]')
if ! echo "$VALID_CATS" | grep -qw "$CAT_LOWER"; then
    CAT_LOWER="all"
fi

# ── URL-encode the query string ──
# Try multiple strategies: python3, python, perl, or fallback to raw
urlencode() {
    local raw="$1"
    # Strategy 1: python3
    if command -v python3 &>/dev/null; then
        python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$raw"
        return 0
    fi
    # Strategy 2: python
    if command -v python &>/dev/null; then
        python -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$raw"
        return 0
    fi
    # Strategy 3: perl (available on most Unix systems, including macOS)
    if command -v perl &>/dev/null; then
        perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$raw"
        return 0
    fi
    # Strategy 4: jq
    if command -v jq &>/dev/null; then
        printf '%s' "$raw" | jq -sRr @uri
        return 0
    fi
    # Strategy 5: fallback — basic sed replacement for common chars
    # This is incomplete but better than nothing
    echo "$raw" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/*/%2A/g;s/+/%2B/g;s/,/%2C/g;s/\//%2F/g;s/:/%3A/g;s/;/%3B/g;s/=/%3D/g;s/?/%3F/g;s/@/%40/g;s/\[/%5B/g;s/\]/%5D/g'
    return 0
}

ENCODED_QUERY=$(urlencode "$QUERY")

# ── Build URL ──
URL="${API_BASE}?token=${TOKEN}&q=${ENCODED_QUERY}&cat=${CAT_LOWER}"

# ── Fetch ──
RAW_TEXT=""
FETCH_ERR=""

if command -v curl &>/dev/null; then
    RAW_TEXT=$(curl -sS --max-time "$TIMEOUT" "$URL" 2>&1) || {
        FETCH_ERR="curl request failed (exit $?)"
    }
else
    FETCH_ERR="curl not found — install curl or ensure it is on PATH"
fi

if [ -n "$FETCH_ERR" ]; then
    echo "{\"error\":\"StyleCool API unreachable\",\"reason\":\"$FETCH_ERR\"}" >&2
    echo "{\"query\":\"$QUERY\",\"cat\":\"$CAT\",\"count\":0,\"results\":[],\"error\":\"unreachable\"}"
    exit 1
fi

if [ -z "$RAW_TEXT" ]; then
    echo "{\"error\":\"StyleCool API returned empty response\"}" >&2
    echo "{\"query\":\"$QUERY\",\"cat\":\"$CAT\",\"count\":0,\"results\":[],\"error\":\"empty_response\"}"
    exit 1
fi

# ── Validate JSON ──
# Quick check: does it start with '{' or '['?
if ! echo "$RAW_TEXT" | grep -qE '^\s*[{\[]'; then
    PREVIEW=$(echo "$RAW_TEXT" | head -c 200)
    echo "{\"error\":\"non-JSON response\",\"body_preview\":\"$PREVIEW\"}" >&2
    echo "{\"query\":\"$QUERY\",\"cat\":\"$CAT\",\"count\":0,\"results\":[],\"error\":\"bad_response\"}"
    exit 1
fi

# ── Process: strip the `css` field, keep only the metadata index ──
# Try jq first (cleanest), then python3, then python, then raw passthrough

process_json() {
    local raw="$1"
    local jq_filter='{
        query: (.query // $ARGS.named.q),
        cat: (.cat // $ARGS.named.c),
        count: (.results | length),
        results: [.results[] | {
            name: ((.name // .["name-en"] // .["name-zh"]) // ""),
            name_zh: (.["name-zh"] // ""),
            desc: ((.desc // .["description-en"] // .["description-zh"]) // ""),
            desc_zh: (.["description-zh"] // ""),
            tags: (.tags // []),
            anti: (.anti // []),
            category: (.category // "")
        }]
    }'

    # Strategy 1: jq
    if command -v jq &>/dev/null; then
        echo "$raw" | jq -c --arg q "$QUERY" --arg c "$CAT" "$jq_filter" 2>/dev/null && return 0
    fi

    # Strategy 2: python3
    if command -v python3 &>/dev/null; then
        echo "$raw" | python3 -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('results', []) if isinstance(data, dict) else []
slim = []
for r in results:
    if not isinstance(r, dict):
        continue
    slim.append({
        'name': r.get('name') or r.get('name-en') or r.get('name-zh') or '',
        'name_zh': r.get('name-zh') or '',
        'desc': r.get('desc') or r.get('description-en') or r.get('description-zh') or '',
        'desc_zh': r.get('description-zh') or '',
        'tags': r.get('tags') or [],
        'anti': r.get('anti') or [],
        'category': r.get('category') or '',
    })
print(json.dumps({'query': data.get('query',''), 'cat': data.get('cat',''), 'count': len(slim), 'results': slim}, ensure_ascii=False))
" 2>/dev/null && return 0
    fi

    # Strategy 3: python
    if command -v python &>/dev/null; then
        echo "$raw" | python -c "
import sys, json
data = json.load(sys.stdin)
results = data.get('results', []) if isinstance(data, dict) else []
slim = []
for r in results:
    if not isinstance(r, dict):
        continue
    slim.append({
        'name': r.get('name') or r.get('name-en') or r.get('name-zh') or '',
        'name_zh': r.get('name-zh') or '',
        'desc': r.get('desc') or r.get('description-en') or r.get('description-zh') or '',
        'desc_zh': r.get('description-zh') or '',
        'tags': r.get('tags') or [],
        'anti': r.get('anti') or [],
        'category': r.get('category') or '',
    })
print(json.dumps({'query': data.get('query',''), 'cat': data.get('cat',''), 'count': len(slim), 'results': slim}, ensure_ascii=False))
" 2>/dev/null && return 0
    fi

    # Strategy 4: raw passthrough (model can parse it)
    echo "$raw"
}

process_json "$RAW_TEXT"
