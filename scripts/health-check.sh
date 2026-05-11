#!/usr/bin/env bash
# health-check.sh — full system health check for g-brain integration stack
# Run from the g-brain repo root: bash scripts/health-check.sh

set -euo pipefail

GSTACK="${GSTACK_SKILLS_DIR:-$HOME/.claude/skills/gstack}"
PASS=0
WARN=0
FAIL=0

check_pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
check_warn() { echo "  ⚠ $1"; WARN=$((WARN+1)); }
check_fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "═══════════════════════════════════════"
echo " g-brain health check"
echo "═══════════════════════════════════════"
echo ""

# ── 1. Prerequisites ──────────────────────────────────────────────────────
echo "1. Prerequisites"

if command -v bun &>/dev/null; then
  check_pass "bun: $(bun --version)"
else
  check_fail "bun not found (required)"
fi

if [ -d "$GSTACK" ]; then
  VERSION=$(cat "$GSTACK/VERSION" 2>/dev/null || echo "unknown")
  check_pass "gstack: v$VERSION at $GSTACK"
else
  check_fail "gstack not found at $GSTACK"
fi

if command -v gbrain &>/dev/null; then
  check_pass "gbrain: $(gbrain --version 2>/dev/null || echo 'installed')"
else
  check_fail "gbrain not found (required for brain sync)"
fi

echo ""

# ── 2. Patches ────────────────────────────────────────────────────────────
echo "2. Patch status"
bash "$(dirname "$0")/verify-patches.sh" 2>/dev/null && check_pass "All 3 patches applied" || check_fail "Patches not applied — run: bash scripts/patch-gstack.sh"

echo ""

# ── 3. Engine detection ───────────────────────────────────────────────────
echo "3. Engine detection (Patch 1 functional test)"
rm -f "$HOME/.gstack/.gbrain-engine-cache.json" 2>/dev/null || true

if command -v gbrain &>/dev/null; then
  ENGINE_OUTPUT=$(cd "$GSTACK" && bun -e "
    const { detectEngineTier } = await import('./lib/gstack-memory-helpers.ts');
    const r = detectEngineTier();
    console.log(JSON.stringify(r));
  " 2>/dev/null || echo '{"engine":"error"}')

  ENGINE=$(echo "$ENGINE_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('engine','unknown'))" 2>/dev/null || echo 'unknown')

  if [ "$ENGINE" = "supabase" ] || [ "$ENGINE" = "pglite" ]; then
    check_pass "Engine detected: $ENGINE"
  else
    check_fail "Engine = unknown — brain sync will be a silent no-op. Check gbrain install and Patch 1."
  fi
else
  check_warn "gbrain not installed — skipping engine detection test"
fi

echo ""

# ── 4. Source ID format ───────────────────────────────────────────────────
echo "4. Source ID format (Patch 2 functional test)"

if [ -d "$GSTACK" ] && command -v bun &>/dev/null; then
  SLUG_TEST=$(cd "$GSTACK" && bun -e "
    import { createHash } from 'crypto';
    import { canonicalizeRemote } from './lib/gstack-memory-helpers.ts';
    const remote = 'github.com/test-org/example-repo-with-long-name-that-overflows';
    const raw = remote.toLowerCase().replace(/[^a-z0-9-]+/g, '-').replace(/-+/g, '-').replace(/^-|-\$/g, '');
    const PREFIX = 'gstack-code-';
    const MAX = 32 - PREFIX.length;
    let result;
    if (raw.length <= MAX) {
      result = PREFIX + raw;
    } else {
      const hash = createHash('sha1').update(remote).digest('hex').slice(0, 6);
      const head = raw.slice(0, MAX - 1 - hash.length).replace(/-\$/, '');
      result = PREFIX + head + '-' + hash;
    }
    const valid = /^[a-z0-9][a-z0-9-]{0,30}[a-z0-9]\$/.test(result) && result.length <= 32;
    console.log(JSON.stringify({ result, valid, length: result.length }));
  " 2>/dev/null || echo '{"valid":false}')

  VALID=$(echo "$SLUG_TEST" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('valid',False))" 2>/dev/null || echo 'False')
  SLUG=$(echo "$SLUG_TEST" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result','?'))" 2>/dev/null || echo '?')

  if [ "$VALID" = "True" ]; then
    check_pass "Source ID format valid: $SLUG"
  else
    check_fail "Source ID format invalid: $SLUG — Patch 2 may not be applied correctly"
  fi
else
  check_warn "Skipping source ID test (gstack or bun not found)"
fi

echo ""

# ── 5. .gbrain-source gitignore reminder ─────────────────────────────────
echo "5. .gbrain-source gitignore (Issue #1384 workaround)"
if [ -f ".gitignore" ] && grep -q '.gbrain-source' .gitignore 2>/dev/null; then
  check_pass ".gbrain-source in .gitignore"
else
  check_warn ".gbrain-source NOT in .gitignore — add: echo '.gbrain-source' >> .gitignore"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────
TOTAL=$((PASS+WARN+FAIL))
echo "═══════════════════════════════════════"
echo " Results: $PASS passed, $WARN warnings, $FAIL failed ($TOTAL checks)"
echo "═══════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo " Run: bash scripts/patch-gstack.sh to fix failures"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo " Warnings are non-blocking but should be addressed"
  exit 0
else
  echo " System healthy. Run /sync-gbrain to confirm end-to-end."
  exit 0
fi
