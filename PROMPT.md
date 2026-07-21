# Setup prompt

Two ways to run this. Both do the same thing.

- **Slash command:** open this folder in Claude Code and type `/setup-clay`.
- **Copy-paste:** paste the prompt below into Claude Code (with this folder open).

Use whichever you like. The copy-paste version is handy if you are new to slash commands or want to tweak the steps.

---

```
Set up my Clay enrichment workflow, following the recipe in this repo's CLAUDE.md.

Do this in order:
1. Confirm I am signed in to Clay (run clay whoami). If not, tell me to run clay login and wait.
2. Ask me for my ICP: industry, country, and company size. Ask for the webhook URL where enriched leads should be sent (a Zapier, Make, or n8n catch hook, or my own endpoint).
3. Search Clay for matching companies and people. This is free, so page through a real sample and show me names and domains to confirm the targeting before spending anything.
4. Build a Clay workflow that enriches each company (firmographics), finds work emails, and adds an HTTP API node that POSTs each enriched record to my webhook. Use provider actions that bill Clay credits and need no API key of my own. Before wiring the HTTP API node, check that no workspace account with a bearer token is auto-bound to it, so my token is never sent to the webhook.
5. Before spending any Clay credits, show me the estimated cost and my current balance, and wait for my explicit go.
6. Run my found leads through the workflow, then tell me how many records were enriched, how many were pushed to the webhook, and how many credits were spent. Give me the workflow link so I can iterate in the Clay app.

Rules: only ever touch my own Clay workspace and my own credits. Keep search free. Confirm before every credit-costing step. Never read or print my Clay token. Do not try to create a Clay table (that is UI only); build a workflow instead.
```

---

Nothing here spends a credit until step 6, and only after you say go.
