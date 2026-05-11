# Ralph

Opt-in autonomous PRD execution loop. Separate from gstack.

## Hard prerequisite
`prd.json` must exist in the project root. If absent, do not run Ralph.

## Loop behaviour
1. Read `prd.json`.
2. Pick highest-priority incomplete story (`passes: false`).
3. Implement.
4. Run checks (lint, tests).
5. Commit.
6. Mark `passes: true` in `prd.json`.
7. Append learnings to `progress.txt`.
8. Repeat until all stories pass.

## Stop condition
All stories in `prd.json` have `passes: true`.

## Hard rules
- Never use Ralph as a general workflow skill.
- Write end-of-sprint learnings to `tasks/lessons.md` via `/learn` manually.
