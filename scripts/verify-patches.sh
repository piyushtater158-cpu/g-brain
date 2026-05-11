#!/usr/bin/env bash
# verify-patches.sh — confirms all 3 g-brain patches are applied correctly
# Run from the g-brain repo root: bash scripts/verify-patches.sh

set -euo pipefail

GSTACK="${GSTACK_SKILLS_DIR:-$HOME/.claude/skills/gstack}"
PASS=0
FAIL=0

check_pass() { echo "  ✓ $1"; PASS=$((PASS+1)); }
check_fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "[g-brain] Verifying patches against: $GSTACK"
echo ""

# ── Patch 1 verification ─────────────────────────────────────────────────
echo "Patch 1 — detectEngineTier (Issue #1415)"
TARGET="$GSTACK/lib/gstack-memory-helpers.ts"

if [ ! -f "$TARGET" ]; then
  check_fail "File not found: $TARGET"
else
  if grep -q 'stdout.*err.*stdout' "$TARGET" 2>/dev/null || grep -q 'err as.*stdout' "$TARGET" 2>/dev/null; then
    check_pass "execSync error.stdout fallback present"
  else
    check_fail "execSync error.stdout fallback MISSING — Patch 1 not applied"
  fi

  if grep -q 'config.json' "$TARGET" && grep -q 'gbrain.*config' "$TARGET" 2>/dev/null; then
    check_pass "~/.gbrain/config.json fallback present"
  else
    check_fail "~/.gbrain/config.json fallback MISSING — Patch 1 (part 2) not applied"
  fi
fi

echo ""

# ── Patch 2 verification ─────────────────────────────────────────────────
echo "Patch 2 — deriveCodeSourceId (Issue #1357)"
TARGET2="$GSTACK/bin/gstack-gbrain-sync.ts"

if [ ! -f "$TARGET2" ]; then
  check_fail "File not found: $TARGET2"
else
  if grep -q 'a-z0-9-' "$TARGET2" 2>/dev/null; then
    check_pass "[^a-z0-9-]+ sanitizer present"
  else
    check_fail "[^a-z0-9-]+ sanitizer MISSING — Patch 2 not applied"
  fi

  if grep -q '32 - PREFIX.length\|MAX.*20\|gstack-code-.*length.*MAX' "$TARGET2" 2>/dev/null || grep -q 'MAX = 32' "$TARGET2" 2>/dev/null; then
    check_pass "32-char limit enforcement present"
  else
    check_fail "32-char limit enforcement MISSING — Patch 2 (part 2) not applied"
  fi
fi

echo ""

# ── Patch 3 verification ─────────────────────────────────────────────────
echo "Patch 3 — gstack-learnings-log investigation type (Issue #1423)"
TARGET3="$GSTACK/bin/gstack-learnings-log"

if [ ! -f "$TARGET3" ]; then
  check_fail "File not found: $TARGET3"
else
  if grep -q "'investigation'" "$TARGET3"; then
    check_pass "'investigation' present in ALLOWED_TYPES"
  else
    check_fail "'investigation' MISSING from ALLOWED_TYPES — Patch 3 not applied"
  fi

  # Live test: actually invoke the binary
  if command -v bun &>/dev/null; then
    TEST_INPUT='{"skill":"investigate","type":"investigation","key":"g-brain-verify","insight":"verify script test","confidence":7,"source":"observed"}'
    if echo "$TEST_INPUT" | "$GSTACK/bin/gstack-learnings-log" /dev/stdin &>/dev/null 2>&1; then
      check_pass "Live invocation: investigation type accepted by binary"
    else
      check_fail "Live invocation: binary rejected investigation type — check ALLOWED_TYPES edit"
    fi
  else
    echo "  - Live test skipped (bun not found)"
  fi
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────
TOTAL=$((PASS+FAIL))
echo "Results: $PASS/$TOTAL checks passed"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Some patches are not applied. Run: bash scripts/patch-gstack.sh"
  exit 1
else
  echo ""
  echo "All patches verified. Run /sync-gbrain to confirm end-to-end."
  exit 0
fi
