# Token budget

How g-brain keeps context lean.

## Baseline problem

Loading gstack + graphify + Ralph always = ~13,000–15,000 token floor before the user types anything. This pushed simple tasks (e.g. `/review` on a 3-file PR) into expensive Opus territory with no quality benefit.

## Budget targets

| Scenario | Target | How |
|----------|--------|-----|
| Simple task (review, QA, investigate) | < 6K tokens | gstack preamble + one skill only |
| Large repo navigation | < 9K tokens | gstack + graphify (on demand) |
| Full PRD execution | < 11K tokens | All layers active |

## Rules that enforce the budget

### Rule 1: Never load graphify unless triggered

Trigger conditions:
- Repo has >50 source files
- User explicitly says "navigate codebase" / "find all usages of" / "where is X defined"
- `/graphify` is explicitly invoked

Do NOT load graphify for: `/review`, `/qa`, `/investigate` (unless the investigation requires cross-file navigation), `/ship`, or any non-navigation task.

### Rule 2: Never activate Ralph unless `prd.json` exists

Ralph rewrites task framing. Loading it on non-PRD tasks breaks skill routing and adds ~1.5K tokens of irrelevant context. Absence of `prd.json` = Ralph is zero-cost.

### Rule 3: Do not load gstack reference docs

These files are NOT agent instructions. Do not read them into context unless explicitly needed:
- `BROWSER.md` (60KB)
- `CHANGELOG.md` (550KB)
- `TODOS.md` (104KB)
- `ARCHITECTURE.md` (30KB)

They are reference docs for humans and upgrade scripts, not for agent context.

### Rule 4: Use Sonnet unless the task requires Opus

Opus costs ~5x Sonnet. Use Opus only for:
- Architecture-level design reviews
- Security audits
- Multi-file refactors >2000 lines net diff

For everything else: Sonnet.

## What was saved vs naive integration

| Configuration | Token floor | Cost per simple task (est.) |
|---------------|-------------|------------------------------|
| Naive (all always, Opus) | ~14,000 | High |
| g-brain (gated, Sonnet) | ~3,500–5,000 | Low |
| g-brain + graphify (large repo) | ~6,000–8,000 | Medium |
| g-brain + all layers (PRD) | ~9,000–11,000 | Medium |
