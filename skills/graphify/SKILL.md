# graphify

On-demand codebase knowledge graph. Separate from gstack — activate only when needed.

## Activate only when
- The codebase is large or unfamiliar.
- File-by-file reading would be too expensive.

## Commands

| Command | Purpose |
|---|---|
| `/graphify .` | Build graph. Run once per repo. |
| `graphify path <file>` | Trace dependencies of a file. |
| `graphify query <term>` | Find all code touching a concept. |
| `graphify explain <symbol>` | Explain a function/class in full context. |
| `graphify update .` | Refresh after significant code changes. |

## Hard rule
Do NOT install graphify as a global PreToolUse hook.
