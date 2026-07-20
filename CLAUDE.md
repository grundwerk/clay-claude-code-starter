# Clay + Claude Code starter: agent recipe

You are helping a GTM / RevOps user stand up a **pull leads, enrich them, push them out**
workflow in Clay, driven from Claude Code. When the user opens this repo and says
"set up my Clay", "build my enrichment", or runs `/setup-clay`, follow the recipe below.

You have two Clay surfaces available:

- The **`clay` CLI** on PATH (JSON output, typed exit codes). Use it for auth, search,
  the action catalog, running workflows and routines, checking credits.
- The **Clay MCP server** (`clay mcp`, wired in `.mcp.json`). Use its tools
  (`read`, `edit_node`, `validate_workflow`, `execute_clay_action`) to build the workflow
  graph node by node.

## Hard rules (read these first)

1. **Only ever touch the user's own workspace and spend the user's own Clay credits.**
   Never route anything through any other account.
2. **Search is free. Enrichment costs credits.** `clay search` does not spend credits.
   Every workflow node that enriches (finds an email, appends firmographics, finds people)
   spends the user's Clay credits. Before any credit-costing run, show the estimate and
   the current balance, and get an explicit "go".
3. **Confirm before every credit-costing step.** Never kick off an enrichment run silently.
4. **Never read or print the Clay token.** It lives in `~/.config/clay/config.json`.
   Do not open, cat, or echo that file. Auth is proven only via `clay whoami`.
5. **Clay tables can only be created in the Clay UI.** The CLI and API cannot create a
   table. Do not try. This recipe builds a **workflow** and runs found leads through it,
   which needs no UI table.
6. **Discover actions, do not guess them.** The Clay action catalog is per workspace.
   Always pull the real catalog (`clay workflows actions list`) and confirm an action with
   `execute_clay_action` before wiring it. Refer to actions by their human readable names
   when talking to the user (for example "Enrich Company", "Work Email"), never by internal
   keys.

## Step A: check auth

```bash
clay whoami; echo "exit_code=$?"
```

- `exit_code=0` with a `user` / `workspace` object: authenticated, continue.
- `exit_code=3` (auth error): run `clay login`. It opens a browser, the user signs in and
  picks a workspace, and the session is stored locally. This works from inside the agent;
  it waits up to 5 minutes for the browser round trip. If your tool cannot wait that long,
  ask the user to run `clay login` in their own terminal, then poll `clay whoami` until it
  exits 0.

If you just ran `clay login`, note that the MCP server only reads the session at startup.
If the MCP tools return an auth error afterward, tell the user to restart Claude Code
(fully quit and reopen) so the `clay mcp` server picks up the new session.

Confirm the workspace and current credit balance before doing anything that spends:

```bash
clay whoami | jq '{user: .user.name, workspace: .workspace.id}'
clay credits | jq '{balance, actionExecutionBalance}'
```

## Step B: get the ICP and the push target

Ask the user for their target profile and where enriched leads should go. Keep it short:

- **Industry** (one or more)
- **Country** (one or more)
- **Company size** (headcount band)
- **Push target**: an HTTPS webhook URL that should receive the enriched records
  (for example a Zapier / Make / n8n catch hook, or their own endpoint).

Optionally, for the people side, ask for target **job titles** and **seniority**.

## Step C: pull leads with search (free)

Search is a three step, forward only iterator: discover fields, create a search, page it.
Do this for **companies** and, if the user wants contacts, for **people**.

Discover the valid filters first. `--source-type` is exactly `companies` or `people`
(plural). It is NOT `company`.

```bash
clay search filters-mode fields --source-type companies | jq '.fields[] | {name, allowedValues}'
clay search filters-mode fields --source-type people   | jq '.fields[] | {name, allowedValues}'
```

Map the user's ICP onto the real field names you just listed. Useful company filters
include `industries`, `country_names`, `sizes`, `annual_revenues`,
`location_states_include`, `location_cities_include`, `funding_amounts`, `types`.
Useful people filters include `job_title_keywords`, `job_title_seniority_levels_v2`
(values: founder, owner, board-member, partner, c-suite, vp, director, head, manager,
senior, mid-level, entry, intern, unknown), `company_industries_include`,
`company_sizes`, `location_countries_include`. Only use field names and allowed values
that the `fields` output actually returned.

Create and page a company search (values below are examples, use the user's ICP):

```bash
clay search filters-mode create --source-type companies \
  --filters '{"industries":["Software Development"],"country_names":["United States"],"sizes":["50","200"]}'
```

`create` returns `{ "searchId": "..." }`. Take that id and pull a page:

```bash
clay search filters-mode run <searchId> --limit 25 | jq '.data'
```

Repeat the `run` call while `hasMore` is `true` to keep paging. Do the same for people if
the user wants contacts. Show the user a short sample of what was found (names, domains,
titles) so they can confirm the targeting before you spend anything.

## Step D: build the enrichment workflow

Enrichment lives in a Clay **workflow** made of tool nodes, each running one Clay action.

1. Create the workflow and share its link right away so the user can watch:

   ```bash
   clay workflows create --name "Starter: enrich and push"
   ```

   This returns `{ id, name, url, ... }`. Post the `url` to the user immediately.

2. Discover the enrichment actions this workspace has:

   ```bash
   clay workflows actions list > /tmp/clay-actions.json
   jq -r '.data[] | select(.type=="function") | .name' /tmp/clay-actions.json
   ```

   The built in Clay enrichments you will typically want:
   - **Emails**: "Work Email", "Enrich Person and Find Contact Details"
   - **Roles / contacts**: "Person Job Title", "Find People at Company", "Enrich Person"
   - **Firmographics**: "Enrich Company", "Company Industry", "Company Employee Count",
     "Company Revenue (Exact)"

   When more than one action does roughly the same thing (there are many email finders),
   do not pick silently. List the human readable options with their credit cost and let the
   user choose.

3. Before wiring any action, test it once to confirm it is available and to see the real
   output field names, using the MCP tool `execute_clay_action` on a single sample record
   (for example one domain from Step C). Enrich (tool) node output is wrapped in a
   `toolResult` envelope, so downstream references are `$.toolResult.result.<field>`.

4. Build the graph node by node with the MCP `edit_node` tool. A tool node has
   `nodeType: "tool"` and exactly one entry in `tools` with the action's `actionKey` and
   `actionPackageId` (read them from the catalog in step 2). Wire each action's inputs with
   `inputMappingConfig` (`static` or `reference` values, `{{variable}}` references to
   upstream output). A minimal chain:
   - Node 1: Enrich Company (input: the company domain)
   - Node 2: Find People at Company or Person Job Title (input: the enriched company)
   - Node 3: Work Email (input: the person)
   - Node 4: push out (see Step E)

5. Validate and show the graph:

   ```bash
   # via the MCP validate_workflow tool with prettier=true to auto-layout, then:
   clay workflows diagram <workflowId>
   ```

## Step E: push the enriched records to the webhook

Add a final tool node that sends each enriched record to the user's push target. Use the
Clay **"HTTP API"** action (`actionKey: http-api-v2`, package "Clay"): method `POST`, URL
set to the user's webhook URL, body built from the enriched fields
(`$.toolResult.result.<field>` from the upstream enrichment nodes). Confirm the exact input
schema with `execute_clay_action` before wiring it.

If the user would rather Clay **receive** leads (an inbound trigger) instead of pushing out,
that is a separate concept: `clay webhooks create <url>` returns a signing secret exactly
once. That is not needed for the push-out flow above.

## Step F: run the found leads through it, then report credits

Run a first batch as a **test run**, feeding the leads found in Step C. This is the credit
spending step, so show the estimate and get an explicit go first:

```bash
clay credits | jq '.balance'   # note the "before" balance
```

Feed found records into a workflow test run (one record shown, batch the same way):

```bash
echo '{"domain":"example.com"}' | clay workflows runs test <workflowId> --input -
```

Poll the run until it is done and inspect results:

```bash
clay workflows runs get <workflowId> <runId> | jq '{status}'
clay workflows runs steps <workflowId> <runId>
```

To make this repeatable at scale, register the workflow as a routine and run batches
through it (note: a workflow may need to be enabled for "API & CLI" in the Clay UI first;
if `runs start` returns not found / exit 6, that enablement is the gap):

```bash
clay routines create workflow <workflowId> --name "Starter enrich and push"
clay routines runs start workflow:<workflowId> --input '{"items":[{"id":"r1","inputs":{"domain":"example.com"}}]}'
clay routines runs get <routineRunId> | jq '{status}'
```

When the run finishes, report the credits consumed as a simple delta:

```bash
clay credits | jq '.balance'   # "after" balance; consumed = before - after
```

Tell the user: how many records were enriched, how many pushed to the webhook, and how many
credits were spent (before minus after). Give them the workflow URL so they can iterate in
the Clay UI.

## What the CLI can and cannot do (be honest with the user)

- **Can**: `clay login` (browser OAuth), `clay search filters-mode` (free lead search),
  `clay workflows create | actions | runs | diagram`, MCP `edit_node` / `validate_workflow`
  / `execute_clay_action` to build the graph, `clay routines` to run at scale,
  `clay webhooks create` (inbound), `clay credits`.
- **Cannot**: create a Clay **table** (UI only), create a Claygent agent node **with tools**
  attached (the user does that in the UI), or spend without the user's credits.
