# Installation Guide

Full install sequence for the g+brain stack: gstack (global workflow) + graphify (on-demand graph nav) + Ralph (opt-in PRD loop).

---

## Prerequisites

- [Bun](https://bun.sh/) >= 1.1
- [gbrain](https://github.com/garrytan/gbrain) >= 0.25 (for memory sync)
- Claude Code CLI
- git

---

## Step 1 — Install gstack globally

```bash
git clone --depth 1 https://github.com/garrytan/gstack ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

> ⚠️ Issue #1383: never run `./setup` or `/gstack-upgrade` from inside Claude Code. Use a plain terminal.

---

## Step 2 — Apply critical patches

Three bugs silently break core functionality. Apply before any use:

### Patch 1 — gbrain engine detection (#1415)

Fix `freshDetectEngineTier()` in `~/.claude/skills/gstack/lib/gstack-memory-helpers.ts`.
Replace the catch block so stdout is read from the error object, and add `~/.gbrain/config.json` fallback.
Full diff: `patches/1415-gbrain-sync-engine-detect.patch`

```bash
rm -f ~/.gstack/.gbrain-engine-cache.json
```

### Patch 2 — source ID slug sanitisation (#1357)

Fix `deriveCodeSourceId()` in `~/.claude/skills/gstack/bin/gstack-gbrain-sync.ts`.
Strip `[^a-z0-9-]+` chars and enforce 32-char max with 6-char hash suffix.
Full diff: `patches/1357-gbrain-source-id.patch`

```bash
rm -f .gbrain-sync-state.json
```

### Patch 3 — investigation learning type (#1423)

In `~/.claude/skills/gstack/bin/gstack-learnings-log`, add `'investigation'` to `ALLOWED_TYPES`:

```diff
- const ALLOWED_TYPES = ['pattern', 'pitfall', 'preference', 'architecture', 'tool', 'operational'];
+ const ALLOWED_TYPES = ['pattern', 'pitfall', 'preference', 'architecture', 'tool', 'operational', 'investigation'];
```

---

## Step 3 — Copy global config

```bash
cp CLAUDE.md ~/.claude/CLAUDE.md
cp settings.json ~/.claude/settings.json
cp settings.local.json ~/.claude/settings.local.json
```

---

## Step 4 — Set up gbrain

```bash
/setup-gbrain
/sync-gbrain
```

---

## Step 5 — Verify

```bash
/health
/gstack
```

---

## Slash command activation rules

See [`docs/GSTACK_SKILLS.md`](GSTACK_SKILLS.md) for the full command list.

- `/graphify .` — large/unfamiliar codebases only. Never global.
- `/ralph` — only when `prd.json` exists. Never general-purpose.
- `/office-hours` — before any new feature.
- `/review` — before any ship.
- `/cso` — before shipping auth or data flows.
- `/investigate` — before touching a bug.
- `/learn` — after any investigation or retro.
- `/context-save` — before long tasks or context compaction.
