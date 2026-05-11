# Architectural decisions

This file records every significant decision made in this project and why. Do not override these decisions without updating this file.

---

## Decision 1: gstack as the global base layer

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** Three tools were candidates for the base layer: gstack, graphify, and Ralph. All three have CLAUDE.md-style instruction files.

**Decision:** gstack is the only always-active layer. It provides the skill runner, memory ingest, brain sync, and global CLAUDE.md conventions.

**Reasoning:**
- gstack has the most complete skill surface (23 skills)
- gstack owns the memory pipeline (learnings.jsonl, brain sync)
- graphify and Ralph are additive; gstack is foundational
- Loading all three always = ~13K token floor; gstack alone = ~3.5K

**Rejected alternatives:** graphify as base (lacks skill runner), Ralph as base (PRD-only scope).

---

## Decision 2: graphify is on-demand only

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** graphify provides codebase navigation via gbrain's `code-refs`, `code-def`, `code-callers`. Useful for large repos. Not needed for small projects or non-code tasks.

**Decision:** Load graphify context only when: (a) repo has >50 files, OR (b) user explicitly asks for code navigation.

**Trigger condition:**
```bash
# In project CLAUDE.md or via /graphify invocation
find . -name '*.ts' -o -name '*.py' -o -name '*.js' | wc -l
# If > 50: load graphify
```

**Reasoning:** ~2.5K token savings on every small-repo task. No quality loss — graphify adds zero value on a 5-file project.

---

## Decision 3: Ralph loop is opt-in via prd.json

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** Ralph's loop rewrites task framing around a PRD. This is useful for structured feature development but disruptive for ad-hoc tasks.

**Decision:** Ralph activates if and only if `prd.json` exists in the project root.

**Reasoning:**
- Explicit trigger = no accidental activation on non-PRD work
- `prd.json` is a natural signal that the user has committed to Ralph's workflow
- Absence of `prd.json` means Ralph is zero-cost (not loaded at all)

**Rejected alternatives:** Env var trigger (too invisible), manual skill invocation only (too manual for loop-style work).

---

## Decision 4: Patch locally, don't fork

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** Three critical bugs in gstack are unpatched upstream. Options: fork gstack, patch locally, or wait.

**Decision:** Apply patches locally to `~/.claude/skills/gstack/`. Maintain patches as `.diff` files in this repo. Remove each patch when upstream fixes it.

**Reasoning:**
- Forking creates a permanent maintenance burden
- Waiting means the integration stack is broken indefinitely
- Local patches are transparent, easy to remove, and track against upstream issues

**Risk:** gstack upgrades will overwrite patches. Mitigation: `verify-patches.sh` runs post-upgrade check.

---

## Decision 5: No Opus for standard tasks

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** Initial design considered Opus for all tasks to maximize quality.

**Decision:** Use Sonnet for all standard invocations. Opus only for: architecture-level design reviews or security audits.

**Reasoning:** ~5x cost difference. No measurable quality gain on `/review`, `/qa`, `/investigate`, or skill invocations. Opus adds genuine value only on tasks requiring deep multi-step reasoning over large context.

---

## Decision 6: Investigation learnings must persist (Patch 3 is load-bearing)

**Date:** 2026-05-11  
**Status:** Accepted

**Context:** Patch 3 adds `'investigation'` to `ALLOWED_TYPES` in `gstack-learnings-log`. This is a one-line fix for Issue #1423.

**Decision:** This patch is mandatory, not optional. Without it, every `/investigate` run silently drops its learnings. Ralph's loop loses all investigation context, breaking the feedback cycle that makes the loop useful.

**Consequence:** If this patch is accidentally reverted (e.g. by a gstack upgrade), investigation-driven context will silently degrade. `verify-patches.sh` checks for this.

---

## Decision 7: `.gbrain-source` must be gitignored manually (Issue #1384)

**Date:** 2026-05-11  
**Status:** Accepted — upstream bug, manual workaround required

**Context:** gstack v1.29.0.0 promised `.gbrain-source` would be added to the consuming repo's `.gitignore` automatically. It was only added to gstack's own `.gitignore`, not the consumer's.

**Decision:** Add this to every project's setup instructions. Add to every project's `.gitignore` on first `/sync-gbrain` run.

```bash
echo '.gbrain-source' >> .gitignore
```

**Remove this decision** when Issue #1384 is fixed upstream.
