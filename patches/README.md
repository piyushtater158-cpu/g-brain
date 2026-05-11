# Patches

Three patches for three silent failures in gstack's current release. Apply all three before using the integration stack.

## Apply all patches

```bash
bash ../scripts/patch-gstack.sh
```

## Verify patches applied

```bash
bash ../scripts/verify-patches.sh
```

---

## Patch 1 — `detectEngineTier()` silent no-op

**File:** `~/.claude/skills/gstack/lib/gstack-memory-helpers.ts`  
**Fixes:** [gstack Issue #1415](https://github.com/garrytan/gstack/issues/1415)  
**Severity:** Critical — breaks all brain sync on Supabase  
**Diff:** [patch-1-engine-detect.ts.diff](patch-1-engine-detect.ts.diff)

**Two-part fix:**
1. `execSync` throws on non-zero exit; read stdout from the error object instead of losing it
2. gbrain ≥0.25 dropped `engine` from `doctor` output; fall back to `~/.gbrain/config.json`

**After applying:** bust the 60s engine cache:
```bash
rm -f ~/.gstack/.gbrain-engine-cache.json
```

---

## Patch 2 — `deriveCodeSourceId` invalid slugs

**File:** `~/.claude/skills/gstack/bin/gstack-gbrain-sync.ts`  
**Fixes:** [gstack Issue #1357](https://github.com/garrytan/gstack/issues/1357)  
**Severity:** Critical — graphify code-nav never works without this  
**Diff:** [patch-2-source-id.ts.diff](patch-2-source-id.ts.diff)

**Two-part fix:**
1. Normalize dots (from `github.com`) using `[^a-z0-9-]+` regex in both code paths
2. Enforce gbrain's 32-char limit with truncation + 6-char hash suffix for uniqueness

**After applying:** bust stale sync state:
```bash
rm -f ~/.claude/skills/gstack/.gbrain-sync-state.json
```

---

## Patch 3 — `gstack-learnings-log` silently drops investigation learnings

**File:** `~/.claude/skills/gstack/bin/gstack-learnings-log`  
**Fixes:** [gstack Issue #1423](https://github.com/garrytan/gstack/issues/1423)  
**Severity:** High — all /investigate learnings silently lost; Ralph loop loses context  
**Diff:** [patch-3-learnings-log.sh.diff](patch-3-learnings-log.sh.diff)

**Fix:** Add `'investigation'` to `ALLOWED_TYPES` array. One line.

**Verify immediately after applying:**
```bash
cd ~/.claude/skills/gstack
echo '{"skill":"investigate","type":"investigation","key":"test-patch3","insight":"patch applied","confidence":8,"source":"observed"}' | bin/gstack-learnings-log /dev/stdin
# Must exit 0 and write to learnings.jsonl
```

---

## Patch status tracker

| Patch | Upstream issue | Upstream status | Remove when |
|-------|---------------|-----------------|-------------|
| Patch 1 | [#1415](https://github.com/garrytan/gstack/issues/1415) | Open (filed 2026-05-10) | Merged to gstack main |
| Patch 2 | [#1357](https://github.com/garrytan/gstack/issues/1357) | Open (filed 2026-05-07) | Merged to gstack main |
| Patch 3 | [#1423](https://github.com/garrytan/gstack/issues/1423) | Open (filed 2026-05-11) | Merged to gstack main |
