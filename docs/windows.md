# Windows install notes

Windows support in gstack has two active bugs that affect the g-brain integration stack.

## Issue #1386 — Memory ingest silent no-op

**Symptom:** Brain score stays at ~10/100 after install. `/sync-gbrain` memory stage reports `imported 0`.  
**Root cause:** Two compounding bugs in `gstack-memory-ingest.ts` since v1.26:
1. `command -v gbrain` probe fails on Windows/Bun — binary detection returns false even when gbrain is in PATH
2. `gbrain put` reads `/dev/stdin` as a literal path — doesn't exist on Windows

**Workaround (upstream fix pending):**
```bash
# Use gbrain import in batch mode instead of per-page gbrain put
# Stage transcripts to a temp dir, then batch import:
gbrain import ~/.gstack/transcripts --workers 4 --json
```

**Upstream link:** https://github.com/garrytan/gstack/issues/1386

## Issue #1375 — Setup script fails (no suffix handling)

**Symptom:** `setup` cannot run on Windows because it has no file extension.  
**Workaround:**
```bash
bash setup
# or
wsl bash setup   # if using WSL
```

**Upstream link:** https://github.com/garrytan/gstack/issues/1375

## Issue #1364 — Chromium fails as root user in WSL2

**Symptom:** `/browse` fails to start Chromium when running as root in WSL2.  
**Workaround:** Set `CI=1` before invoking browse:
```bash
export CI=1
# Now /browse works
```
**Upstream fix:** Add `isRoot` check to `browser-manager.ts`. See issue for one-line patch.  
**Upstream link:** https://github.com/garrytan/gstack/issues/1364
