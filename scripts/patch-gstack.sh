#!/usr/bin/env bash
# patch-gstack.sh — applies all 3 g-brain patches to local gstack install
# Run from the g-brain repo root: bash scripts/patch-gstack.sh

set -euo pipefail

GSTACK="${GSTACK_SKILLS_DIR:-$HOME/.claude/skills/gstack}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCHES_DIR="$(cd "$SCRIPT_DIR/../patches" && pwd)"

echo "[g-brain] gstack install dir: $GSTACK"

if [ ! -d "$GSTACK" ]; then
  echo "[g-brain] ERROR: gstack not found at $GSTACK"
  echo "         Install gstack first: https://github.com/garrytan/gstack"
  exit 1
fi

# ── Patch 1: freshDetectEngineTier (Issue #1415) ─────────────────────────
echo ""
echo "[g-brain] Applying Patch 1: detectEngineTier fix (Issue #1415)..."

TARGET="$GSTACK/lib/gstack-memory-helpers.ts"
if ! grep -q 'freshDetectEngineTier' "$TARGET"; then
  echo "[g-brain] SKIP Patch 1: freshDetectEngineTier not found in $TARGET (may already be fixed upstream)"
else
  # Use Python for reliable in-place replacement (available on all platforms)
  python3 - "$TARGET" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

old = '''function freshDetectEngineTier(): EngineDetect {
  const now = Date.now();
  try {
    const out = execSync("gbrain doctor --json --fast 2>/dev/null", { encoding: "utf-8", timeout: 5000 });
    const parsed = JSON.parse(out);
    const engine: EngineTier = parsed?.engine === "supabase" ? "supabase" : parsed?.engine === "pglite" ? "pglite" : "unknown";
    return {
      engine,
      supabase_url: parsed?.supabase_url || undefined,
      detected_at: now,
      schema_version: 1,
    };
  } catch {
    return { engine: "unknown", detected_at: now, schema_version: 1 };
  }
}'''

new = '''function freshDetectEngineTier(): EngineDetect {
  const now = Date.now();
  let parsed: Record<string, unknown> | null = null;

  // FIX #1415 (part 1): gbrain doctor exits with code 1 when health_score < 100.
  // execSync throws on non-zero exit — stdout is still on the error object.
  try {
    const out = execSync("gbrain doctor --json --fast 2>/dev/null", {
      encoding: "utf-8",
      timeout: 5000,
    });
    parsed = JSON.parse(out);
  } catch (err: unknown) {
    try {
      const stdout = (err as { stdout?: string })?.stdout ?? "";
      if (stdout) parsed = JSON.parse(stdout);
    } catch { /* unparseable stdout */ }
  }

  // FIX #1415 (part 2): gbrain >=0.25 dropped top-level `engine` from doctor output.
  // Fall back to ~/.gbrain/config.json.
  let engine: EngineTier =
    parsed?.engine === "supabase" ? "supabase" :
    parsed?.engine === "pglite"   ? "pglite"   : "unknown";

  if (engine === "unknown") {
    try {
      const configPath = join(homedir(), ".gbrain", "config.json");
      const cfg = JSON.parse(readFileSync(configPath, "utf-8")) as Record<string, unknown>;
      if (cfg?.engine === "pglite") engine = "pglite";
      else if (cfg?.engine === "postgres" || cfg?.database_url) engine = "supabase";
    } catch { /* config unreadable */ }
  }

  return {
    engine,
    supabase_url: (parsed?.supabase_url as string) || undefined,
    detected_at: now,
    schema_version: 1,
  };
}'''

if old in content:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print(f'[g-brain] Patch 1 applied to {path}')
else:
    print(f'[g-brain] Patch 1 SKIP: target block not found (may already be patched or upstream changed)')
PYEOF

  # Bust the engine tier cache so the fixed code runs immediately
  rm -f "$HOME/.gstack/.gbrain-engine-cache.json"
  echo "[g-brain] Engine cache cleared"
fi

# ── Patch 2: deriveCodeSourceId (Issue #1357) ─────────────────────────────
echo ""
echo "[g-brain] Applying Patch 2: deriveCodeSourceId fix (Issue #1357)..."

TARGET2="$GSTACK/bin/gstack-gbrain-sync.ts"
if [ ! -f "$TARGET2" ]; then
  echo "[g-brain] SKIP Patch 2: $TARGET2 not found"
else
  python3 - "$TARGET2" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

old = '''function deriveCodeSourceId(repoPath: string): string {
  const pathHash = createHash("sha1").update(repoPath).digest("hex").slice(0, 8);
  const remote = canonicalizeRemote(originUrl());
  if (remote) {
    const segs = remote.split("/").filter(Boolean);
    const slugSource = segs.slice(-2).join("-");
    return constrainSourceId("gstack-code", `${slugSource}-${pathHash}`);
  }
  const base = repoPath.split("/").pop() || "repo";
  return constrainSourceId("gstack-code", `${base}-${pathHash}`);
}'''

new = '''function deriveCodeSourceId(repoPath: string): string {
  const remote = canonicalizeRemote(originUrl());

  // FIX #1357 (part 1): canonicalizeRemote returns `github.com/org/repo`.
  // Dots survive into the slug and fail gbrain\'s alnum+hyphen validator.
  // Use [^a-z0-9-]+ in both branches (fallback branch was already correct).
  const raw = remote
    ? remote
        .toLowerCase()
        .replace(/[^a-z0-9-]+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-|-$/g, "")
    : (repoPath.split("/").pop() || "repo")
        .toLowerCase()
        .replace(/[^a-z0-9-]+/g, "-")
        .replace(/-+/g, "-")
        .replace(/^-|-$/g, "");

  const PREFIX = "gstack-code-";
  const MAX = 32 - PREFIX.length; // 20 chars available

  // FIX #1357 (part 2): enforce gbrain\'s 32-char limit.
  // Truncate + 6-char hash suffix keeps IDs unique across orgs sharing a basename.
  if (raw.length <= MAX) return PREFIX + raw;

  const hash = createHash("sha1")
    .update(remote || repoPath)
    .digest("hex")
    .slice(0, 6);
  const head = raw.slice(0, MAX - 1 - hash.length).replace(/-$/, "");
  return PREFIX + head + "-" + hash;
}'''

if old in content:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print(f'[g-brain] Patch 2 applied to {path}')
else:
    print(f'[g-brain] Patch 2 SKIP: target block not found (may already be patched or upstream changed)')
PYEOF

  # Bust stale sync state so source ID is registered fresh with the fixed slug
  rm -f "$GSTACK/.gbrain-sync-state.json"
  echo "[g-brain] Sync state cleared"
fi

# ── Patch 3: gstack-learnings-log ALLOWED_TYPES (Issue #1423) ─────────────
echo ""
echo "[g-brain] Applying Patch 3: learnings-log investigation type (Issue #1423)..."

TARGET3="$GSTACK/bin/gstack-learnings-log"
if [ ! -f "$TARGET3" ]; then
  echo "[g-brain] SKIP Patch 3: $TARGET3 not found"
else
  if grep -q "'investigation'" "$TARGET3"; then
    echo "[g-brain] Patch 3 already applied (investigation already in ALLOWED_TYPES)"
  else
    sed -i.bak \
      "s/const ALLOWED_TYPES = \['pattern', 'pitfall', 'preference', 'architecture', 'tool', 'operational'\];/const ALLOWED_TYPES = ['pattern', 'pitfall', 'preference', 'architecture', 'tool', 'operational', 'investigation']; \/\/ FIX #1423/" \
      "$TARGET3"
    echo "[g-brain] Patch 3 applied"
    rm -f "${TARGET3}.bak"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
echo "[g-brain] All patches applied. Run verify-patches.sh to confirm."
echo ""
echo "[g-brain] Next steps:"
echo "  1. bash scripts/verify-patches.sh"
echo "  2. /sync-gbrain   (confirm engine != unknown, code stage = OK)"
echo "  3. echo '.gbrain-source' >> <your-project>/.gitignore  (Issue #1384 workaround)"
