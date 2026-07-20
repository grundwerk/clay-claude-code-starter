#!/usr/bin/env bash
set -euo pipefail

# Clay + Claude Code starter: quickstart
# Idempotent. Safe to run more than once.

bold() { printf '\033[1m%s\033[0m\n' "$1"; }

bold "Clay + Claude Code starter: quickstart"
echo

# The Clay plugin installs a CLI forwarder into ~/.local/bin, so make sure it is on PATH.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# 1) Node.js is NOT required by the Clay CLI (the CLI ships as a self-contained binary
#    bundled with the Claude Code plugin). This is a courtesy, non-blocking check only.
if command -v node >/dev/null 2>&1; then
  echo "Node.js detected: $(node --version 2>/dev/null || echo unknown) (informational, not required by Clay)."
else
  echo "Node.js not found. That is fine: the Clay CLI is a bundled binary and does not need Node.js."
fi
echo

# 2) Clay CLI. There is no npm or curl install for it. It ships with the Clay plugin for
#    Claude Code. If it is missing, print the official install commands and stop cleanly.
if command -v clay >/dev/null 2>&1; then
  echo "clay CLI detected: $(clay --version 2>/dev/null || echo unknown)"
else
  bold "clay CLI not found on PATH."
  cat <<'EOF'

The Clay CLI is not installed via npm or curl. It ships with the Clay plugin for
Claude Code. Install it from INSIDE Claude Code (requires Claude Code v2.1.91 or newer):

    /plugin marketplace add clay-run/agent-plugins
    /plugin install clay@clay-plugins

Then fully restart Claude Code and run this script again (or just run: clay login).
EOF
  exit 0
fi
echo

# 3) Authenticate. Idempotent: skip if already signed in. clay login opens a browser
#    and waits up to 5 minutes for the round trip.
if clay whoami >/dev/null 2>&1; then
  echo "Already signed in to Clay:"
  clay whoami | { jq '{user: .user.name, workspace: .workspace.id}' 2>/dev/null || cat; }
else
  bold "Signing in to Clay (this opens a browser)..."
  clay login
  echo "Signed in:"
  clay whoami | { jq '{user: .user.name, workspace: .workspace.id}' 2>/dev/null || cat; }
fi
echo

# 4) Next steps.
bold "You are set up. Next:"
cat <<'EOF'
  1. Open this folder in Claude Code.
  2. Run the slash command:  /setup-clay
     (or just tell Claude: "set up my Clay").
  3. Claude will search leads (free), build an enrichment workflow, and push the
     results to a webhook you provide. It confirms with you before spending any credits.
EOF
