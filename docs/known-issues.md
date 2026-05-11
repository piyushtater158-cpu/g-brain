# Known issues

Active upstream gstack bugs and their workarounds as of 2026-05-11.

## Critical (break the integration stack)

### Issue #1415 — `detectEngineTier` always returns `engine=unknown` on Supabase
**Status:** Open  
**Affects:** All Supabase gbrain users  
**Patched by g-brain:** Yes — [Patch 1](../patches/patch-1-engine-detect.ts.diff)  
**Upstream PR:** None yet  
**Upstream link:** https://github.com/garrytan/gstack/issues/1415

### Issue #1357 — `deriveCodeSourceId` produces invalid slugs for GitHub HTTPS remotes
**Status:** Open  
**Affects:** Anyone using GitHub HTTPS remotes  
**Patched by g-brain:** Yes — [Patch 2](../patches/patch-2-source-id.ts.diff)  
**Upstream PR:** None yet  
**Upstream link:** https://github.com/garrytan/gstack/issues/1357

### Issue #1423 — `/investigate` learnings silently dropped
**Status:** Open (filed 2026-05-11)  
**Affects:** All users of `/investigate` skill  
**Patched by g-brain:** Yes — [Patch 3](../patches/patch-3-learnings-log.sh.diff)  
**Upstream PR:** None yet  
**Upstream link:** https://github.com/garrytan/gstack/issues/1423

---

## High (break specific workflows)

### Issue #1414 — Cross-machine source-ID collision
**Status:** Open  
**Affects:** Multi-machine setups sharing a gbrain DB (chezmoi, ansible, etc.)  
**Patched by g-brain:** No — requires architecture-level fix in gstack  
**Workaround:** Ensure different absolute home dir layouts per machine  
**Upstream link:** https://github.com/garrytan/gstack/issues/1414

### Issue #1384 — `.gbrain-source` not added to consumer `.gitignore`
**Status:** Open  
**Affects:** All users of `/sync-gbrain`  
**Patched by g-brain:** No  
**Workaround:**
```bash
echo '.gbrain-source' >> .gitignore
```
**Upstream link:** https://github.com/garrytan/gstack/issues/1384

### Issue #1386 — Windows memory ingest silent no-op since v1.26
**Status:** Open  
**Affects:** Windows users  
**Patched by g-brain:** No  
**Workaround:** See [windows.md](windows.md)  
**Upstream link:** https://github.com/garrytan/gstack/issues/1386

---

## Medium (platform-specific)

### Issue #1379 — Headed browse crashes on macOS 26 (Mach rendezvous)
**Status:** Open  
**Affects:** macOS 26 (Tahoe stable) users  
**Workaround:** Use headless mode (default). Don't pass `--headed` to `/browse`.  
**Upstream link:** https://github.com/garrytan/gstack/issues/1379

### Issue #1381 — Apple Silicon codesign failures
**Status:** Open  
**Affects:** arm64 Mac users  
**Workaround:** Run `codesign --force --sign - ~/.claude/skills/gstack/browse/dist/find-browse`  
**Upstream link:** https://github.com/garrytan/gstack/issues/1381

### Issue #1383 — gstack-upgrade auto-proceeds without TTY, leaves state half-done
**Status:** Open  
**Affects:** Anyone running `/gstack-upgrade` from inside Claude Code  
**Workaround:** Always run `./setup` in an interactive terminal, never from an agent runner  
**Upstream link:** https://github.com/garrytan/gstack/issues/1383

---

## Security

### Issue #1370 — Security classifier unwired from PTY injection path
**Status:** Open (HIGH severity)  
**Affects:** Anyone using gstack browse + "Send to Code" on untrusted pages  
**Patched by g-brain:** No — design-level fix required upstream  
**Workaround:** Do not use the Inspector "Send to Code" action on pages you don't control  
**Upstream link:** https://github.com/garrytan/gstack/issues/1370
