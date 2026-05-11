# gstack Skills Reference

All slash commands verified from [garrytan/gstack](https://github.com/garrytan/gstack) repo (commit 49cc4ff).
Use these only when conditions are met. Never activate globally.

---

## Planning & Strategy

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/office-hours` | `office-hours/` | Before starting any new feature or sprint. Forces structured design doc. | Sonnet |
| `/autoplan` | `autoplan/` | One-command pipeline: CEO → design → eng review in sequence. | Sonnet |
| `/plan-ceo-review` | `plan-ceo-review/` | When you need to rethink scope: EXPAND / REDUCE / HOLD / CUT. | Opus |
| `/plan-eng-review` | `plan-eng-review/` | Architecture + test-plan critique before implementation. | Opus |
| `/plan-design-review` | `plan-design-review/` | Visual and UX critique of a plan before building. | Sonnet |
| `/plan-devex-review` | `plan-devex-review/` | Developer-experience critique of APIs, CLIs, and SDKs. | Sonnet |
| `/plan-tune` | `plan-tune/` | Tune an existing plan without full re-review. | Sonnet |

---

## Engineering & QA

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/review` | `review/` | Hunt for production-level bugs, not just style. Run before ship. | Opus |
| `/qa` | `qa/` | Browser-based QA with auto-fix. Requires `/browse` daemon running. | Sonnet |
| `/qa-only` | `qa-only/` | Browser QA without auto-fix; observation mode only. | Sonnet |
| `/investigate` | `investigate/` | Root-cause a bug before touching code. Writes learnings (type: investigation). ⚠️ Apply Patch #1423 first. | Sonnet |
| `/benchmark` | `benchmark/` | Measure and compare implementation performance. | Sonnet |
| `/benchmark-models` | `benchmark-models/` | Compare model outputs side-by-side. | Sonnet |
| `/health` | `health/` | Check system health: gbrain, browser, environment. | Sonnet |
| `/guard` | `guard/` | Runtime guardrails. Intercept dangerous ops before execution. | Sonnet |
| `/careful` | `careful/` | Risk-mitigation pass before any irreversible action. | Sonnet |

---

## Design

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/design` | `design/` | Full design pass on a UI component or page. | Sonnet |
| `/design-review` | `design-review/` | Critique an existing design against brand/UX standards. | Sonnet |
| `/design-consultation` | `design-consultation/` | Interactive design feedback loop. | Sonnet |
| `/design-html` | `design-html/` | Output a design as raw HTML prototype. | Sonnet |
| `/design-shotgun` | `design-shotgun/` | Generate multiple divergent design directions fast. | Sonnet |

---

## Security

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/cso` | `cso/` | OWASP + STRIDE security audit. Run before shipping auth, payments, or user data flows. | Opus |
| `/devex-review` | `devex-review/` | Security + DX review of public-facing APIs and SDKs. | Sonnet |

---

## Release & Deployment

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/ship` | `ship/` | Full PR pipeline: tests, docs, review, commit. | Sonnet |
| `/land-and-deploy` | `land-and-deploy/` | Merge + verify deployment succeeded. | Sonnet |
| `/landing-report` | `landing-report/` | Post-deploy summary report. | Sonnet |
| `/canary` | `canary/` | Canary approval/regression guard after deploy. | Sonnet |
| `/document-release` | `document-release/` | Write developer-facing release notes. | Sonnet |
| `/make-pdf` | `make-pdf/` | Export a document or report to PDF. ⚠️ Run SETUP block manually first (Issue #1389). | Sonnet |

---

## Context & Memory

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/learn` | `learn/` | Write reusable patterns and pitfalls to learnings.jsonl. | Sonnet |
| `/retro` | `retro/` | End-of-sprint retrospective. | Sonnet |
| `/context-save` | `context-save/` | Snapshot current context before a long task or compaction. | Sonnet |
| `/context-restore` | `context-restore/` | Restore a saved context snapshot. | Sonnet |
| `/sync-gbrain` | `sync-gbrain/` | Sync memory to gbrain. ⚠️ Apply Patches #1415 and #1357 first. | Sonnet |
| `/setup-gbrain` | `setup-gbrain/` | First-time gbrain setup and gitleaks install. | Sonnet |

---

## Browser

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/browse` | `browse/` | Start the headless browser daemon. Required for /qa and /scrape. | Sonnet |
| `/open-gstack-browser` | `open-gstack-browser/` | Open the browser in headed mode. ⚠️ Broken on macOS 26 (Issue #1379). | Sonnet |
| `/scrape` | `scrape/` | Scrape a URL into structured data. | Sonnet |
| `/setup-browser-cookies` | `setup-browser-cookies/` | Import browser session cookies for authenticated scraping. | Sonnet |

---

## Meta / Setup

| Command | Folder | When to use | Model |
|---|---|---|---|
| `/gstack` | `gstack/` | Check gstack status and active config. | Sonnet |
| `/gstack-upgrade` | `gstack-upgrade/` | Upgrade gstack. ⚠️ Do NOT run inside Claude Code without TTY (Issue #1383). | Sonnet |
| `/freeze` | `freeze/` | Lock project state before a risky migration. | Sonnet |
| `/unfreeze` | `unfreeze/` | Restore from a frozen state. | Sonnet |
| `/pair-agent` | `pair-agent/` | Spawn a subagent to work in parallel on a separate concern. | Sonnet |
| `/skillify` | `skillify/` | Convert an ad-hoc workflow into a reusable skill. | Sonnet |
| `/setup-deploy` | `setup-deploy/` | Configure deployment target for /land-and-deploy. | Sonnet |

---

## graphify (on-demand — NOT gstack)

| Command | When to use |
|---|---|
| `/graphify .` | First run on a large/unfamiliar repo. Builds graph.json + GRAPH_REPORT.md. |
| `graphify path <file>` | Trace dependencies of a specific file. |
| `graphify query <term>` | Find all code touching a concept. |
| `graphify explain <symbol>` | Explain a function/class in codebase context. |
| `graphify update .` | Refresh graph after code changes. |

> ⚠️ Do NOT add graphify as a global PreToolUse hook.

---

## Ralph (opt-in PRD loop — NOT gstack)

| Command | Condition |
|---|---|
| `/ralph` | `prd.json` must exist in project root. Executes PRD stories one at a time. Stops when all `passes: true`. |

> ⚠️ Do NOT use Ralph as a general workflow skill.

---

## Known Broken Commands (apply patches before use)

| Command | Issue | What breaks | Patch |
|---|---|---|---|
| `/sync-gbrain` | #1415 | Engine always `unknown` on Supabase. All 3 sync stages silently skip. | `patches/1415-gbrain-sync-engine-detect.patch` |
| `/sync-gbrain` | #1357 | Source ID slug has `.` and exceeds 32 chars. Code source never registers. | `patches/1357-gbrain-source-id.patch` |
| `/investigate` | #1423 | All learnings silently dropped (type `investigation` not in ALLOWED_TYPES). | `patches/1423-learning-type.patch` |
| `/gstack-upgrade` | #1383 | Auto-runs without TTY, leaves repo rename half-done. | Run in interactive terminal only |
| `/open-gstack-browser` | #1379 | Crashes on macOS 26 headed mode. | Use headless mode only |
| `/make-pdf` | #1389 | SETUP section buried — agent skips it. | Run SETUP block manually first |
