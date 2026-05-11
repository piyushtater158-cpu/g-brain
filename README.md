# g-brain

> **gstack + graphify + Ralph** — patched, production-ready integration layer.
> All three blockers from the audit are fixed before you run a single command.

---

## What this is

`g-brain` is a thin integration layer that wires three tools together into one coherent AI-agent workflow:

| Tool | Role | When it activates |
|------|------|-------------------|
| **gstack** | Global workflow base — skill runner, memory, brain sync | Always on |
| **graphify** | Large-codebase navigation (`code-refs`, `code-def`, `code-callers`) | On demand, large repos |
| **Ralph loop** | PRD execution skill — plan → implement → verify loop | Opt-in per project |

**Three silent bugs in gstack's current release break this entire stack.** This repo ships the patches. Install them first.

---

## Quick install

```bash
# 1. Clone this repo
git clone https://github.com/piyushtater158-cpu/g-brain.git ~/.g-brain
cd ~/.g-brain

# 2. Run the patcher (applies all 3 fixes to your local gstack install)
bash scripts/patch-gstack.sh

# 3. Verify patches applied correctly
bash scripts/verify-patches.sh

# 4. Run initial brain sync
/sync-gbrain
```

That's it. No build step. No new binaries.

---

## Prerequisites

| Requirement | Version | Check |
|-------------|---------|-------|
| gstack | ≥ v1.26.0.0 | `cat ~/.claude/skills/gstack/VERSION` |
| gbrain | ≥ v0.18.2 | `gbrain --version` |
| bun | ≥ 1.1.0 | `bun --version` |
| Claude Code | any | `claude --version` |

**If you are on Supabase-backed gbrain:** Patch 1 is critical. Without it, every `/sync-gbrain` run silently no-ops and your brain score stays at 0. See [patches/README.md](patches/README.md).

**If you are on Windows:** Patch 1 + the Windows ingest workaround in [docs/windows.md](docs/windows.md) are both required.

**If you are on Apple Silicon macOS 26+:** Headed browse mode has a Mach rendezvous bug in gstack v1.28. Use headless mode (default) until upstream fixes it. See [docs/known-issues.md](docs/known-issues.md).

---

## Repository structure

```
g-brain/
├── README.md                   # This file
├── CLAUDE.md                   # Agent instructions (read by Claude Code on every session)
├── ARCHITECTURE.md             # Layer design, token model, decision log
├── DECISIONS.md                # All architectural decisions made in this project
├── patches/
│   ├── README.md               # Which patch fixes which issue, why it matters
│   ├── patch-1-engine-detect.ts.diff    # Fix #1415: detectEngineTier silent no-op
│   ├── patch-2-source-id.ts.diff        # Fix #1357: invalid slug + 32-char overflow
│   └── patch-3-learnings-log.sh.diff    # Fix #1423: 'investigation' type silently dropped
├── scripts/
│   ├── patch-gstack.sh         # Applies all 3 patches to local gstack install
│   ├── verify-patches.sh       # Validates all patches applied correctly
│   └── health-check.sh         # Full system health check (gstack + gbrain + Ralph)
├── docs/
│   ├── windows.md              # Windows-specific install notes
│   ├── known-issues.md         # Active upstream bugs and workarounds
│   └── token-budget.md         # How we keep context lean
└── .github/
    └── workflows/
        └── verify.yml          # CI: runs verify-patches.sh on every push
```

---

## Layer architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Claude Code session                  │
└────────────────────────┬────────────────────────────────┘
                         │ reads
                         ▼
┌─────────────────────────────────────────────────────────┐
│  CLAUDE.md  (global ~/.claude/CLAUDE.md)                │
│  • Core rules, token budget, skill routing              │
│  • gstack skill prefix config                           │
│  • Ralph loop trigger conditions                        │
└──────────┬──────────────────────┬───────────────────────┘
           │ always loaded        │ on demand
           ▼                      ▼
┌──────────────────┐   ┌──────────────────────────────────┐
│    gstack        │   │  graphify (large repo nav)        │
│  skills + brain  │   │  Trigger: repo > 50 files OR     │
│  sync + memory   │   │  explicit /graphify invocation   │
└──────────┬───────┘   └──────────────────────────────────┘
           │ opt-in
           ▼
┌─────────────────────────────────────────────────────────┐
│  Ralph loop (PRD execution)                             │
│  Trigger: prd.json present in project root              │
│  Files: prd.json, progress.txt, .ralph/                 │
└─────────────────────────────────────────────────────────┘
```

**Token load model:**
- gstack preamble: ~3-4K tokens (always loaded, cached)
- graphify context: ~2-3K tokens (only when triggered)
- Ralph skill: ~1-2K tokens (only when `prd.json` exists)
- **Total worst case: ~9K tokens** vs ~10K+ before optimization

---

## The three patches — why they matter

### Patch 1 — `detectEngineTier()` ([Issue #1415](https://github.com/garrytan/gstack/issues/1415))

**What breaks without it:** `/sync-gbrain` always returns `engine=unknown` for Supabase users. All three sync stages skip silently. No error. Brain never syncs. Graphify's code-nav never has data.

**Root cause:** `gbrain doctor` exits with code 1 when `health_score < 100` (which is always true on a fresh install). `execSync` throws on non-zero exit — the JSON on stdout is lost. The catch block returns `{ engine: "unknown" }` immediately.

**Second root cause:** gbrain ≥0.25 changed `doctor` output to `schema_version:2`, which dropped the top-level `engine` field entirely.

### Patch 2 — `deriveCodeSourceId()` ([Issue #1357](https://github.com/garrytan/gstack/issues/1357))

**What breaks without it:** `deriveCodeSourceId` produces slugs containing `.` (from `github.com`) and slugs >32 chars. gbrain's `sources add` validator rejects both. The code source is never registered. `gbrain code-def`, `code-refs`, `code-callers` never work for your repo — graphify is dead on arrival.

**Root cause:** The remote branch only replaces `/` and whitespace. The fallback branch correctly uses `[^a-z0-9-]+`. The two branches disagree. Neither enforces gbrain's 32-char limit.

### Patch 3 — `gstack-learnings-log` ([Issue #1423](https://github.com/garrytan/gstack/issues/1423))

**What breaks without it:** The `/investigate` skill logs learnings with `type:"investigation"`. But `ALLOWED_TYPES` in `gstack-learnings-log` doesn't include `"investigation"`. Every `/investigate` run silently drops its entire learning history. Ralph's loop loses all investigation context.

**Root cause:** One-line omission in the allowed types array.

---

## Skill routing (copy this to your CLAUDE.md)

```
## g-brain routing

- Bugs / errors → /investigate (Ralph loop writes to progress.txt if prd.json present)
- Code navigation in large repo → /graphify then continue
- Brain sync check → /sync-gbrain
- PRD execution → ensure prd.json exists, then Ralph loop auto-activates
- All other workflows → standard gstack routing
```

---

## Known upstream issues (open, unpatched)

These are NOT fixed in this repo — they require upstream gstack changes:

| Issue | Impact | Workaround |
|-------|--------|------------|
| [#1414](https://github.com/garrytan/gstack/issues/1414) | Cross-machine source-ID collision (same path, two machines) | Use unique home dir layouts per machine |
| [#1384](https://github.com/garrytan/gstack/issues/1384) | `.gbrain-source` not added to `.gitignore` automatically | Add manually: `echo '.gbrain-source' >> .gitignore` |
| [#1383](https://github.com/garrytan/gstack/issues/1383) | v1.27 migration auto-proceeds without TTY, leaves state half-done | Run `./setup` only in interactive terminal, never from agent runner |
| [#1379](https://github.com/garrytan/gstack/issues/1379) | Headed browse fails on macOS 26 (Mach rendezvous) | Use headless mode (default) |
| [#1386](https://github.com/garrytan/gstack/issues/1386) | Windows: memory ingest silent no-op since v1.26 | See docs/windows.md |
| [#1370](https://github.com/garrytan/gstack/issues/1370) | Security classifier unwired from PTY injection path | Don't use browse + "Send to Code" on untrusted pages |

---

## Contributing

This repo patches an upstream project. Before opening a PR:

1. Check if the issue is already fixed upstream in gstack
2. If yes — remove the corresponding patch file and update `scripts/patch-gstack.sh`
3. If no — add a new patch with a link to the upstream issue

Do not add features here. Features belong in gstack, graphify, or Ralph upstream.
