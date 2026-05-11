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

When the user's request matches an available skill, invoke it via the Skill tool. When in doubt, invoke the skill. A false positive is cheaper than a false negative.

### Product / Strategy
| Intent | Route to |
|--------|----------|
| User describes a new idea, brainstorms, pitches a concept, "is this worth building" | `/office-hours` |
| User asks about strategy, scope, ambition, "think bigger", "what should we build" | `/plan-ceo-review` |
| User asks to review architecture, lock in the plan, "does this design make sense" | `/plan-eng-review` |
| User asks about design system, brand, visual identity, "how should this look" | `/design-consultation` |
| User asks to review design of a plan | `/plan-design-review` |
| User asks about developer experience of a plan, API/CLI/SDK design | `/plan-devex-review` |
| User wants all reviews done automatically, "review everything" | `/autoplan` |
| User wants to tune question sensitivity, "stop asking me that" | `/plan-tune` |

### Engineering / QA
| Intent | Route to |
|--------|----------|
| Bugs / errors, "why is this broken", "this doesn't work", "wtf" | `/investigate` (requires Patch #1423) |
| User asks to test the site, find bugs, QA, "does this work", "check the deploy" | `/qa` |
| User asks to just report bugs without fixing | `/qa-only` |
| User asks to review code, check the diff, pre-landing review | `/review` |
| User asks about visual polish, design audit of a live site | `/design-review` |
| User asks to audit the live developer experience, time-to-hello-world | `/devex-review` |
| User wants pair programming with a subagent | `/pair-agent` |
| User asks for weekly retro, what did we ship, "how'd we do" | `/retro` |
| User asks for a second opinion, codex review | `/codex` |

### Design
| Intent | Route to |
|--------|----------|
| Structured design workflow | `/design` |
| Design consultation before building | `/design-consultation` |
| Generate or review HTML/UI design | `/design-html` |
| Review existing design artifacts | `/design-review` |
| Rapid parallel design exploration | `/design-shotgun` |

### Security
| Intent | Route to |
|--------|----------|
| Security audit, OWASP, vulnerabilities, "is this secure" | `/cso` |
| User asks for safety mode, careful mode | `/careful` |
| User asks for a safety guard before risky operations | `/guard` |

### Release
| Intent | Route to |
|--------|----------|
| Ship / deploy / PR, "let's land this", "send it" | `/ship` |
| Merge + deploy + verify as one flow | `/land-and-deploy` |
| Configure deployment pipeline | `/setup-deploy` |
| Monitor prod after shipping, post-deploy checks | `/canary` |
| Post-deploy landing report | `/landing-report` |
| Update docs after shipping | `/document-release` |

### Memory / Brain
| Intent | Route to |
|--------|----------|
| Write and reuse project patterns, "what has gstack learned" | `/learn` |
| Upgrade gstack | `/gstack-upgrade` |
| Brain sync check | `/sync-gbrain` (requires Patches #1415 and #1357) |
| Initial gbrain setup | `/setup-gbrain` |

### Context Management
| Intent | Route to |
|--------|----------|
| Save progress, checkpoint, "save my work" | `/context-save` |
| Resume, restore, "where was I" | `/context-restore` |
| Restrict edits / lock files | `/freeze` |
| Unfreeze previously frozen state | `/unfreeze` |

### Browser / Scraping
| Intent | Route to |
|--------|----------|
| Web scraping within a session | `/scrape` |
| Launch real browser for QA, "open the browser" | `/open-gstack-browser` |
| Configure browser cookies for authenticated testing | `/setup-browser-cookies` |

### Utilities
| Intent | Route to |
|--------|----------|
| Full system health check | `/health` |
| Convert workflow or doc into a reusable skill | `/skillify` |
| Generate a PDF from content | `/make-pdf` |
| Browser/claw tool integration | `/openclaw` |
| Page speed, performance regression, benchmarks | `/benchmark` |
| Code navigation in large repo (>50 files) | `/graphify` first, then continue |
| PRD execution | Ensure `prd.json` in project root — Ralph loop auto-activates |

---

## GBrain Search Guidance

When gbrain is configured and this worktree is pinned:
- Prefer `gbrain search` / `gbrain query` over Grep for semantic questions.
- Use `gbrain code-def` / `code-refs` / `code-callers` for symbol-aware code lookup.
- Run `/sync-gbrain` to refresh.

---

## Token budget rules

- Do NOT load graphify context unless the repo has >50 files OR the user explicitly asks for code navigation.
- Do NOT activate Ralph loop unless `prd.json` exists in the project root.
- Do NOT load gstack BROWSER.md, CHANGELOG.md, or TODOS.md into context. They are reference docs, not agent instructions.
- If context is approaching limit, save with `/context-save` before proceeding.

---

## Model tier

| Tier | Use for |
|------|--------|
| **Opus** | `/cso`, `/plan-ceo-review`, `/plan-eng-review`, `/review` on complex tasks |
| **Sonnet** (default) | Everything else |

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
