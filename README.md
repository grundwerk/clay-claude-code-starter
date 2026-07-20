# Clay + Claude Code starter

**Clay shipped a CLI and an MCP server. That means you can wire Clay into Claude Code and
have the agent build your enrichment setup for you.** Clone this repo, add your Clay login,
tell Claude Code to set it up, and in about 5 minutes you have a working pull leads, enrich
them, push them out workflow.

## What you get

A repo that turns Claude Code into your Clay operator. Point it at your ICP and a webhook,
and the agent will:

- **Pull**: search Clay's GTM database for your target companies and people. This is free.
- **Enrich**: build a real Clay workflow that appends emails, roles, and firmographics.
- **Push**: send every enriched record to a webhook you provide (Zapier, Make, n8n, your
  own endpoint, whatever you use).

You stay in control: the agent confirms with you before spending a single Clay credit.

## Prerequisites

- A **Clay account** (any plan with credits and workspace Editor or Admin access).
- **Claude Code v2.1.91 or newer**.
- The **Clay plugin for Claude Code**, which bundles the `clay` CLI and the `clay mcp`
  server. There is no separate npm or curl install: the CLI ships with the plugin. Node.js
  is not required.

## 5-minute quickstart

1. **Clone the repo**

   ```bash
   git clone https://github.com/grundwerk/clay-claude-code-starter.git
   cd clay-claude-code-starter
   ```

2. **Install the Clay plugin** (once, from inside Claude Code):

   ```
   /plugin marketplace add clay-run/agent-plugins
   /plugin install clay@clay-plugins
   ```

   Then fully restart Claude Code so the plugin loads.

3. **Sign in to Clay.** Run the quickstart script, which checks your setup and signs you in
   with browser OAuth:

   ```bash
   bash scripts/quickstart.sh
   ```

   (Equivalent manual step: just run `clay login`.) Prefer an API key for CI instead of
   browser OAuth? See `.env.example`.

4. **Open this folder in Claude Code and run:**

   ```
   /setup-clay
   ```

   Or just tell it: "set up my Clay". The agent asks for your ICP (industry, country, size)
   and a webhook URL, then does the rest.

## How it works

Clay exposes two surfaces that this repo plugs into Claude Code:

- The **`clay` CLI** (JSON output, typed exit codes) for auth, free lead search, the action
  catalog, running workflows, and checking credits.
- The **Clay MCP server** (`clay mcp`, wired in `.mcp.json`) that gives the agent live tools
  to build a Clay workflow node by node (`read`, `edit_node`, `validate_workflow`,
  `execute_clay_action`).

The playbook the agent follows lives in `CLAUDE.md`. In short: it authenticates, searches
Clay for your ICP (free), builds a workflow that chains Enrich Company, find people or job
titles, and Work Email, adds an HTTP API node that POSTs each enriched record to your
webhook, then runs your found leads through it and reports the credits spent. It discovers
the real actions in your workspace rather than guessing, and it asks you to choose when
several actions do the same job.

One design note: **Clay tables can only be created in the Clay UI.** The CLI and MCP cannot
create a table. So this starter is built entirely around Clay **workflows**, **search**, and
**webhooks**, none of which need a UI created table.

## Costs

Be clear on this before you run anything:

- **Search is free.** Finding companies and people with `clay search` does not spend credits.
- **Enrichment uses your own Clay credits.** Every step that finds an email, appends
  firmographics, or finds people spends credits from your workspace, at your workspace's
  rates. This starter never spends anything without showing you the balance and getting your
  explicit go first. Check your balance any time with `clay credits`.

Nothing here routes through anyone else's account. It is your workspace and your credits,
end to end.

## FAQ

**Do I need to build a Clay table first?**
No. Table creation is UI only, and this starter does not use one. It searches Clay's
database directly and runs found leads through a workflow.

**Does searching cost credits?**
No. `clay search` is free. Only enrichment steps spend credits.

**Where does my Clay login live? Is it safe?**
`clay login` stores a local session in `~/.config/clay/config.json`. The agent never reads
or prints it. Nothing is committed to the repo (`.env` is gitignored).

**Can I use an API key instead of browser login?**
Yes, mainly for CI or for building your own service on Clay's Public API. Create one with
`clay api-keys create --name "starter"` (the secret is shown once) or in Clay under Settings,
Account, API keys (beta). For interactive use, `clay login` is simpler. See `.env.example`.

**Where do enriched leads end up?**
Wherever you point them. You give the agent an HTTPS webhook URL, and it adds a push node
that POSTs each enriched record there.

**Can I change the workflow later?**
Yes. The agent gives you a link to the workflow in the Clay app. Edit it there, or ask
Claude Code to change it.

---

Built by [Grundwerk Digital](https://grundwerk.digital).
