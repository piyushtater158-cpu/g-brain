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

## Key commands
See `docs/GSTACK_SKILLS.md` for full list with conditions and model tiers.

- `/office-hours` — structured feature intake
- `/plan-eng-review` — architecture critique
- `/review` — production bug hunt
- `/ship` — full PR pipeline
- `/investigate` — root-cause before fixing (apply Patch #1423 first)
- `/learn` — write reusable lessons
- `/cso` — security audit
- `/sync-gbrain` — memory sync (apply Patches #1415 and #1357 first)
