---
description: Set up a Clay pull, enrich, push workflow end to end from your ICP.
---

Set up my Clay enrichment workflow by following the recipe in this repo's `CLAUDE.md`.

Do this in order:

1. **Check auth.** Run `clay whoami`. If it fails with an auth error, run `clay login`
   and wait for me to finish the browser sign in. Confirm my workspace and show my current
   credit balance (`clay credits`).
2. **Ask my ICP and push target.** Get my target industry, country, and company size, and
   the HTTPS webhook URL where enriched leads should be sent. Optionally ask for target job
   titles and seniority for contacts.
3. **Pull leads for free.** Use `clay search filters-mode` (companies, and people if I want
   contacts) to find matching leads. Show me a short sample so I can confirm the targeting.
   This step is free, it does not spend credits.
4. **Build the enrichment workflow.** Create a Clay workflow (`clay workflows create`) and
   share the link. Discover the real enrichment actions (`clay workflows actions list`),
   and when several actions do the same job, list the human readable options with their
   credit cost and let me choose. Build the graph with the Clay MCP tools (`edit_node`,
   `validate_workflow`), testing each action with `execute_clay_action` before wiring it.
   Chain: Enrich Company, then find people or job titles, then Work Email, then an HTTP API
   node that POSTs each record to my webhook.
5. **Run it, but confirm first.** Enrichment spends my Clay credits. Show me the estimate
   and my balance, wait for my explicit go, then run my found leads through the workflow.
6. **Report.** Tell me how many records were enriched, how many were pushed to the webhook,
   and how many credits were spent (balance before minus after). Give me the workflow URL.

Hard rules: only my workspace and my credits, search is free, confirm before every credit
costing step, never read or print my Clay token, and do not try to create a Clay table
(that is UI only, this recipe uses a workflow instead).
