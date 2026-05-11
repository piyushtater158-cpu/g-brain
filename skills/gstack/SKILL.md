# gstack

gstack is the global workflow discipline layer. Always active once installed.

## Role
- Plan before implementing.
- Use subagents only when they reduce main context.
- Learn from mistakes via `/learn`.
- Verify before claiming done.

## Hard rules
- No global PreToolUse hooks for graphify or memory sync.
- Keep `enableAllProjectMcpServers: false`.
- Sonnet by default. Opus only for `/cso`, `/plan-ceo-review`, `/plan-eng-review`, `/review` on complex tasks.

---

## Full Command Reference

### Product / Strategy
| Command | When to use |
|---|---|
| `/office-hours` | Before starting a feature; force-structured design doc |
| `/plan-ceo-review` | Rethink scope; four modes: expansion, reduction, hold, etc. |
| `/plan-eng-review` | Architectural and test-plan review |
| `/plan-design-review` | Pre-implementation design sign-off |
| `/plan-devex-review` | Developer experience review before shipping |
| `/plan-tune` | Tune/optimize an existing plan |
| `/autoplan` | One-command CEO → design → eng review pipeline |

### Engineering / QA
| Command | When to use |
|---|---|
| `/review` | Hunt for production-like bugs, not just style |
| `/qa` | Live browser-based QA with fixes |
| `/qa-only` | Browser QA without auto-fix |
| `/investigate` | Root-cause debugging before changing code (requires Patch #1423) |
| `/retro` | End-of-sprint engineering retrospective |
| `/devex-review` | Developer experience audit on existing code |
| `/pair-agent` | Pair programming with a subagent |

### Design
| Command | When to use |
|---|---|
| `/design` | Run a structured design workflow |
| `/design-consultation` | Get design consultation before building |
| `/design-html` | Generate/review HTML/UI design |
| `/design-review` | Review existing design artifacts |
| `/design-shotgun` | Rapid parallel design exploration |

### Security
| Command | When to use |
|---|---|
| `/cso` | OWASP + STRIDE-style audit (use Opus) |
| `/careful` | Runtime guardrails and risk-mitigation checks |
| `/guard` | Safety guard before destructive or risky operations |

### Release
| Command | When to use |
|---|---|
| `/ship` | PR-generation with tests, docs, and reviews |
| `/land-and-deploy` | Merge + deploy verification |
| `/canary` | Canary-approval / regression-guard after deploy |
| `/landing-report` | Post-deploy landing report |
| `/document-release` | Generate release documentation |
| `/setup-deploy` | Configure deployment pipeline |

### Memory / Brain
| Command | When to use |
|---|---|
| `/learn` | Write and reuse project-specific patterns and pitfalls |
| `/gstack-upgrade` | Keep gstack updated without losing config |
| `/sync-gbrain` | Sync brain memory (requires Patches #1415 and #1357) |
| `/setup-gbrain` | Initial gbrain setup and configuration |

### Context Management
| Command | When to use |
|---|---|
| `/context-save` | Save current session context before hitting limits |
| `/context-restore` | Restore a previously saved context |
| `/freeze` | Freeze current state (lock files/config) |
| `/unfreeze` | Unfreeze previously frozen state |

### Browser / Scraping
| Command | When to use |
|---|---|
| `/scrape` | Web scraping within a session |
| `/open-gstack-browser` | Open the gstack browser integration |
| `/setup-browser-cookies` | Configure browser cookies for authenticated scraping |

### Utilities
| Command | When to use |
|---|---|
| `/health` | Full system health check (gstack + gbrain) |
| `/skillify` | Convert any workflow or doc into a reusable gstack skill |
| `/make-pdf` | Generate a PDF from content |
| `/openclaw` | Browser/claw tool integration |

---

## Model Tier Guide

| Tier | Commands |
|---|---|
| **Opus** | `/cso`, `/plan-ceo-review`, `/plan-eng-review`, `/review` (complex tasks only) |
| **Sonnet** (default) | Everything else |

---

## g-brain Routing Override

These commands are handled by g-brain layers, not vanilla gstack:

- `/investigate` → Ralph loop writes findings to `progress.txt` if `prd.json` present
- `/sync-gbrain` → requires Patches #1415 and #1357 (applied by `scripts/patch-gstack.sh`)
- Large repo code nav → trigger `/graphify` first, then continue with any command
