# g-brain architecture

## Overview

Three layers. Each layer activates independently. No layer depends on another being active.

```
Layer 1: gstack       — always on     — skill runner + memory + brain sync
Layer 2: graphify     — on demand     — large codebase navigation
Layer 3: Ralph loop   — opt-in        — PRD execution and verification
```

## Why this layering

**Problem we solved:** The naive integration loaded everything always — gstack preamble + graphify context + Ralph skill + Opus model for all tasks. This pushed simple tasks to ~10K+ tokens with Opus pricing, and caused `/review` to time out on small PRs.

**Solution:** Gate each layer behind an explicit trigger. Only gstack loads by default. Graphify loads when repo size warrants it. Ralph only activates when a `prd.json` file is present.

## Token budget

| Layer | Tokens (approx) | When loaded |
|-------|-----------------|-------------|
| gstack preamble | ~3,500 | Always |
| gstack skill (e.g. /review) | ~800–2,000 | Per invocation |
| graphify context | ~2,500 | Large repos only |
| Ralph skill | ~1,500 | prd.json present |
| **Max total** | **~9,500** | All layers active |

Compare to naive load (all always): ~13,000–15,000 tokens before the user types a word.

## State files

| File | Owner | Purpose |
|------|-------|---------|
| `~/.gstack/.gbrain-engine-cache.json` | gstack | 60s engine-tier cache. Bust after Patch 1. |
| `~/.claude/skills/gstack/.gbrain-sync-state.json` | gstack | Sync stage state. Bust after Patch 2. |
| `~/.gstack/projects/$SLUG/learnings.jsonl` | gstack | Learning history. Patch 3 ensures investigation learnings land here. |
| `~/.gbrain/config.json` | gbrain | Engine config. Patch 1 reads this as fallback. |
| `.gbrain-source` (project root) | gbrain | Per-worktree source pin. Add to `.gitignore` manually (Issue #1384). |
| `prd.json` (project root) | Ralph | Trigger file. Absence means Ralph is inactive. |
| `progress.txt` (project root) | Ralph | Ralph loop state. Gitignore this. |

## Patch dependency graph

```
Patch 1 (engine detect)
  └─► enables brain sync to work
        └─► enables Patch 2 (source ID) to register successfully
              └─► enables graphify code-nav to have data
                    └─► enables Ralph loop to have full context

Patch 3 (learnings log) — independent
  └─► enables /investigate learnings to persist
        └─► enables Ralph to accumulate investigation context over time
```

Apply patches in order: 1, 2, 3.

## What was deliberately excluded

These were considered and rejected:

| Decision | Rejected option | Why |
|----------|-----------------|-----|
| Always-load graphify | Load on every session | Adds ~2.5K tokens to every task, including trivial ones like `/review` on 3-file PRs |
| Global Ralph activation | Add Ralph to global CLAUDE.md | Ralph rewrites task framing; breaks non-PRD workflows |
| Opus as default model | Use Opus for all tasks | ~5x cost vs Sonnet with no quality gain on code review, QA, or skill invocations |
| Load gstack BROWSER.md always | Include in global context | 60KB file; loads in ~15K tokens; only relevant for `/browse` invocations |
| Patch upstream directly | Fork gstack | Maintenance burden. We apply patches locally and track upstream issue status. |

## Upgrade strategy

When gstack releases a new version:

1. Check if the upstream fix for each of the 3 issues has landed
2. If yes: remove the corresponding patch file from `patches/` and update `scripts/patch-gstack.sh`
3. If no: re-apply the patch against the new version (line numbers may shift)
4. Run `scripts/verify-patches.sh` to confirm
5. Update the issue status table in [docs/known-issues.md](docs/known-issues.md)

Track upstream fix status at:
- Patch 1: https://github.com/garrytan/gstack/issues/1415
- Patch 2: https://github.com/garrytan/gstack/issues/1357
- Patch 3: https://github.com/garrytan/gstack/issues/1423
