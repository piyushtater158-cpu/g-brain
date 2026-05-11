# g-brain agent instructions

## What this repo is

This is the g-brain integration layer. It patches gstack to fix three critical silent failures, then wires gstack + graphify + Ralph into a single coherent workflow.

**Read this file fully before taking any action in this repo.**

---

## Commands

```bash
bash scripts/patch-gstack.sh      # apply all 3 patches to local gstack
bash scripts/verify-patches.sh    # confirm patches applied correctly
bash scripts/health-check.sh      # full system health: gstack + gbrain + Ralph
```

**Never run `setup` or `./setup` from this repo.** This repo has no build step. It patches another tool.

---

## Patch application rules

1. Always run `verify-patches.sh` after `patch-gstack.sh`. Do not assume the patch applied.
2. If a patch fails (e.g. line numbers shifted due to upstream update), check the diff manually against the current file.
3. After Patch 1 applies, **always bust the engine cache**: `rm -f ~/.gstack/.gbrain-engine-cache.json`
4. After Patch 2 applies, **always bust sync state**: `rm -f ~/.claude/skills/gstack/.gbrain-sync-state.json`
5. After Patch 3 applies, run the one-line verification in `scripts/verify-patches.sh` to confirm `investigation` type is accepted.

---

## Brain sync state

After applying patches, run `/sync-gbrain` once manually to confirm:
- `engine=supabase` or `engine=pglite` (NOT `engine=unknown`)
- `code` stage reports `OK` (not `ERR source registration failed`)
- `memory` stage reports `OK`

If any stage shows `ERR`, stop and diagnose before continuing.

---

## Skill routing

| Intent | Route to |
|--------|----------|
| Bugs / errors | `/investigate` |
| Code navigation (large repo) | `/graphify` first, then continue |
| Brain sync check | `/sync-gbrain` |
| PRD execution | Ensure `prd.json` in project root, Ralph loop auto-activates |
| Strategy / scope | `/plan-ceo-review` |
| Architecture | `/plan-eng-review` |
| Code review | `/review` |
| QA | `/qa` |
| Ship / deploy | `/ship` |

---

## Token budget rules

- Do NOT load graphify context unless the repo has >50 files OR the user explicitly asks for code navigation.
- Do NOT activate Ralph loop unless `prd.json` exists in the project root.
- Do NOT load gstack BROWSER.md, CHANGELOG.md, or TODOS.md into context. They are reference docs, not agent instructions.
- If context is approaching limit, save with `/context-save` before proceeding.

---

## What NOT to do

- Do NOT run `gstack-upgrade` from inside Claude Code. It auto-proceeds without TTY and can leave state half-done (Issue #1383).
- Do NOT use `git add .` or `git add -A` in gstack's directory. Compiled binaries are tracked by mistake and will be staged.
- Do NOT run headed browse mode on macOS 26. It crashes immediately (Issue #1379). Headless works fine.
- Do NOT trust `/health`'s `security` field. The security classifier is unwired from the PTY injection path (Issue #1370).
- Do NOT use the same absolute home dir layout on two machines sharing a gbrain DB (Issue #1414, cross-machine source-ID collision).

---

## After any gstack upgrade

1. Re-run `bash scripts/verify-patches.sh` — upgrades overwrite patched files
2. If verification fails, re-run `bash scripts/patch-gstack.sh`
3. Bust caches: `rm -f ~/.gstack/.gbrain-engine-cache.json ~/.claude/skills/gstack/.gbrain-sync-state.json`
4. Run `/sync-gbrain` and confirm all stages report `OK`

---

## Architecture decisions (do not override)

These decisions were made deliberately. Do not reverse them without reading DECISIONS.md.

1. **gstack is the base layer** — always active, never replaced by graphify or Ralph
2. **graphify is on-demand** — trigger only on large repos or explicit request; never load always
3. **Ralph is opt-in** — activates only when `prd.json` is present; never inject into global CLAUDE.md
4. **Patches live in this repo, not upstream** — until upstream fixes are merged, we maintain our own patched files
5. **No Opus for simple tasks** — use Sonnet unless the task is architecture-level design or security audit
6. **Investigation learnings must persist** — Patch 3 is load-bearing for Ralph's context accumulation
