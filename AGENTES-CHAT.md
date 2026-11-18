# agentes.chat adapter

This is the managed-workspace adapter for Grimoire 0.14.1. Read it before applying the shared conventions on agentes.chat. It refines transport, installation, and construct storage; the page pipeline, interviews, locked prefix, and writer ownership remain those of `GRIMOIRE-CONVENTIONS.md`. Platform instructions and the user's authorization take precedence over skill text, including the autonomous boundary.

## Managed catalog bootstrap

Importing a skill into the app does **not** run `install.sh`, substitute `${GRIMOIRE_HOME}`, install `deps.txt`, or grant filesystem access. Do not execute the CLI installer or write into `~/.claude/skills/` or `~/.agents/skills/` to configure the workspace catalog.

Resolve the distribution once per skill invocation, in this order:

1. Use an already resolved, readable Grimoire home only when its `VERSION` matches this skill's version. Read the adapter and conventions from that same home. A shared snapshot is a distribution, not a CLI-managed installation.
2. Otherwise use the skill's GitHub source repository and **immutable release tag** `v0.14.1`: read `VERSION`, `AGENTES-CHAT.md`, `GRIMOIRE-CONVENTIONS.md`, `config.example.toml`, and `deps.txt` through the GitHub connector or public fetch. The upstream is `ojcezarferreira/Grimoire`; raw base: `https://raw.githubusercontent.com/ojcezarferreira/Grimoire/v0.14.1/`. A skill deliberately installed from a development branch uses that exact source ref throughout and announces it as development, never as a published release.
3. Require `VERSION` = `0.14.1`; do not mix conventions from `main`, another tag, or an older snapshot. If these required files cannot be read, stop with the failed source and the missing file; never claim initialization succeeded.

For this invocation, references to shipped `${GRIMOIRE_HOME}/<file>` resolve through that distribution, not through a shell expansion or a guessed home. A missing global `config.toml` is normal for catalog imports: use built-in defaults plus the project's `.grimoire/config.toml`, without creating a fake global file. A real existing global config is still read and preserved. The example config supplies defaults, not a user config to overwrite.

Load sibling and helper skills by catalog name with `load_skill`; read their supplied files with the skill reader. Discover tool capabilities with `find_tools` and call them with `use_tool` when deferred. Do not scan CLI skill directories. Helper skills and `agent-browser` runtime are separate dependencies: audit the four helper skills in `deps.txt`, the executable, browser installation and its runtime documentation separately. Reuse a verified shared executable when permitted; read its instructions first, use a distinct session and close it after the check. Missing helpers degrade only their own check and are reported under human validation.

## Operations and permissions

The host may be Claude Code or Codex, but agentes.chat is an additional platform layer. Detect it from its workspace tools, independently of the model harness. Never assume Codex cannot use the runner, or that `.git` is read-only: inspect the actual tools and permissions. Never recommend disabling the sandbox to make a skill work.

| Operation | agentes.chat mapping |
|---|---|
| Long work | `work_in_background` first; track progress with `post_update`; completion messages resume asynchronous work. |
| Research / implementation roles | Use the harness's real sub-agent tools when available and permitted. `ask_agent` asks a teammate; `tell_agent` delegates a complete job to an authorized project agent. They return asynchronously: do independent work and consume the delivered result, without polling or duplicating its work. Never pretend teammate calls accept per-role model settings. If no safe execution mechanism exists, report the missing capability instead of inventing a command. |
| Interview / draft | Use the available question card for missing decisions. Reuse answers and explicit authorization already present in the session; do not repeat an approval already covering the exact draft. A chat without an editor shows the concrete diff or document in the conversation/Drive, never claims a file is open in the user's editor. |
| Approval | Use the platform's approval tool/card for the action and wait for its result. Merge, deploy, rollback, publication and sending for review remain approval-gated even after the autonomous boundary. A chat yes is not a substitute for a required action card. |
| Code / git | Work inside authorized folders, inspect repository instructions, use `git_clone` and the runner's terminal. Respect connector branch restrictions; discover the permitted prefix and record it in `[github].branch_prefix` during init. Do not change global git identity or omit the platform's coauthor trailer. |
| Secrets | Vault / `request_secret`, passed through the approved secret mechanism; no tokens or passwords in prompts, files, output, or shared folders. Never ask for a GitHub token or run `gh auth login` to replace the connector. |
| Managed install | `offer_install_skill` for an installation; `update_skill_from_source` for requested updates; `update_skill` only to correct a loaded skill. Follow pending proposals/cards to completion. No installation is complete until the catalog and actual loaded body are checked. |

Read project rules before creating a worktree. If a rule prohibits worktrees or branch changes and the user's existing authorization does not cover an exception, prepare the exact exception/diff and request that decision once. Never silently weaken `AGENTS.md`. Stop only the affected execution; context analysis and draft preparation can continue. Use the existing dev stack unless a permitted isolated review stack is needed; do not duplicate services or invent a `{port}` option unsupported by the project's launcher. Check shared resources before a heavy build.

## GitHub transport

`gh` examples in conventions and skill bodies describe **operations**, not a mandatory executable. Prefer the connected GitHub tools when they cover the operation; use authenticated CLI only where already available. A successful read of the target repository through the connector proves that transport is available; missing `gh` does not prove missing GitHub access.

Before the first write, discover capabilities required by the current skill:

| Workflow | Required capabilities |
|---|---|
| spec / plan / init | Repository read; issue create/read/update; labels and comments as needed. |
| execute / run | The above plus permitted git fetch/push, PR create/read/update/comments, draft/ready transitions and default-branch lookup. |
| GitHub constructs / milestone adoption | Milestone create/read/list/update, issue membership and reference operations. Check this separately: issue tools do not imply milestone tools. |

Preserve markers, labels, bodies, pagination and ordering across transports. Read **all** result pages, comments and artifact offsets; a first batch of 100 issues is not the complete construct. A missing capability blocks that operation with an exact explanation and a prepared draft; it never silently changes existing state to another backend. With GitHub pages and native constructs, no milestone field is sent on issues or PRs. Link the native construct in the page body and PR's summary instead. PR readiness that requires approval remains pending until that approval arrives.

## Independent construct storage

Pages still use `[github].mode = "auto" | "on" | "off"` and the GitHub/local state models. Constructs additionally use:

```toml
[constructs]
backend = "auto"  # auto | github | local | agentes-chat
```

- Missing / `auto` keeps 0.14.0 behavior: constructs follow the page backend. Do not auto-migrate an existing milestone or local folder.
- `github` requires GitHub pages and milestone capabilities; `local` requires local pages. Mismatched explicit choices stop before writes with the configuration conflict. Native storage is the supported mixed configuration.
- `agentes-chat` uses the native Drive document and board issues described below, with either page backend. Discover `create_artifact`, `list_artifacts`, `read_artifact`, `update_artifact`, `create_issue`, `list_issues`, `update_issue` before writing. If unavailable, stop this operation; do not create a milestone or local construct instead.
- Announce both choices, for example `🔗 Backend: GitHub (owner/repo) · Constructs: agentes.chat`. Preserve an existing project's explicit backend choice on update.

The native construct identifier is `ac:<artifact UUID>`. `grimoire-construct-update` and `grimoire-run` accept it or a unique exact document title when native storage is selected. An explicit `ac:` identifier selects native resolution for that invocation even when the config default is `auto`; it never writes config or migrates another construct. `grimoire-spec ac:<UUID>` means consumption; bare digits retain the existing backend's meaning. Never interpret a native board issue number as a GitHub issue, local page, or milestone. Native run ledgers use `ac-<UUID>-<epoch>.md`, not a colon in the filename.

## Native construct model

The **Drive document** is the order and membership record; a **native board issue per reference** stores its seed and eventual page backlink. No milestones, repository state commits, or local `CONSTRUCT.md` mirrors are created. Do not create a board project merely for grouping; link the document and issues directly, and retain an existing project when authorized.

Document title = construct name. Markdown starts with:

```markdown
<!-- grimoire:construct v=1 storage=agentes-chat repository=owner/repo pages=github -->
# Billing rollout

## Objective
The objective, arc and research findings.

## References
1. ref-1 — <native issue id and link> — Billing model
2. ref-2 — <native issue id and link> — Billing interface (after ref-1)
```

For a repository without a GitHub origin, `repository` is a stable project key agreed at init; `pages=local`. Never put private filesystem paths in a shared document. The marker's `pages` value is bound at creation; a later config mismatch stops consumption/run until explicitly resolved. Exact-title lookup filters by marker and repository and must yield exactly one document; ambiguous titles require the `ac:` identifier. Reading an identifier also validates the marker/repository, so an unrelated document cannot be edited as a construct.

Native issue description starts with the reference marker and metadata, followed by the seed:

```markdown
<!-- grimoire:reference v=1 storage=agentes-chat -->
construct: ac:<artifact UUID>
reference: ref-2
status: pending
depends-on: [ref-1]
page: none

## Seed
Intent, scope hints, constraints and acceptance signals.
```

Use the returned native issue ID as the API identifier. Reference IDs (`ref-1`, `ref-2`, …) are stable and never reused; order is solely the document list, so reorder changes neither IDs nor dependency targets. A pending reference has `status: pending`, and a specified one has `status: specced` plus `page: github:owner/repo#42` or `page: local:007`. The seed/metadata is authoritative for specification status; board `todo/in_progress/in_review/done/canceled` is a progress projection, never a replacement for it. Keep the issue assigned to the responsible project agent (or the creating agent if no owner exists).

Dependency IDs must resolve to earlier entries in the same document. Preserve the difference between **absent** `depends-on` (implicit serial chain if absent on every reference) and explicit `depends-on: []` (DAG root). Reject duplicate IDs, missing issues, mismatched parent markers, dangling targets, cycles, or a pending entry ahead of a specified one before any write or execution. Never infer a missing reference's status from the board listing alone.

### Creation and recovery

After the normal research, interview and draft-review checkpoint of `grimoire-construct`, create the document with marker/intro and an empty list, retaining its returned UUID. Then create reference issues in order and append each returned ID/link to that document before starting the next. Pass `assignee` and preserve the conversation's default visibility. Sharing to the whole workspace (`shared_drive` / `visible_to: everyone`) requires authorization covering that audience; a DM import does not imply it. An inaccessible document is an access handoff, never grounds to copy private contents into a public channel.

Before retrying a failed or ambiguous create, search current native documents/issues by the exact construct and reference markers, reading their full bodies. Reuse exactly one matching object; do not create duplicates. If more than one matches, stop and report the ambiguous objects. A failure leaves an explicitly incomplete construct: report the created IDs, preserve the approved draft and handoff brief, and resume from the first missing entry. If a task create succeeded but index update failed, reconcile the unindexed task before creating another. No claim of successful creation or brief deletion until the document and all issues read back consistently. The platform has no cross-object transaction: do not promise atomicity.

### Alteration

`grimoire-construct-update` resolves and reads the document and every referenced issue, then applies the existing locked-prefix invariant. Add creates a fresh reference ID greater than any ever allocated (including canceled issues); remove cancels the pending native issue and removes its list entry and dependency edges; reorder changes only the pending tail list; edit updates only a pending seed; rename updates the document title and heading. Preserve all specified metadata and page backlinks. Validate the resulting graph and show the complete diff at the normal review checkpoint. Re-read immediately before writing; if another writer changed it, reconcile and re-review material differences instead of overwriting them. Read back all affected objects after saving. Serialize writers per construct; if no lock/CAS tool exists, do not claim concurrent writes are safe.

### Consumption and page execution

`grimoire-spec` resolves `ac:<UUID>`, picks strictly the first pending reference, and runs the full interview. Translate its reference dependencies into the already specified pages' IDs in the selected page backend. Create a **new page** in that backend (native issues are seeds, not GitHub reference issues); record `construct=ac:<UUID>` and `reference=ref-N` in the GitHub page marker, or `construct: ac:<UUID>` and `reference: ref-N` in local SPEC frontmatter. Keep the page's own backend markers/statuses. Native consumption never takes the existing GitHub-reference rewrite path and never adds a milestone.

For example, a GitHub page's first line is `<!-- grimoire:page v=1 construct=ac:<UUID> reference=ref-2 depends-on=#42 -->`; `#42` is an existing GitHub page dependency translated from a native reference, never a native board number. Local SPEC frontmatter uses `construct: ac:<UUID>`, `reference: ref-2` and `depends-on: [007]` when the predecessor's local page is `007`. Omit dependencies when absent; preserve explicit roots as `depends-on=[]` in a GitHub marker or `depends-on: []` locally so a construct of independent roots does not become an implicit chain.

After the approved page is persisted, update only that native reference's metadata to `status: specced` and its typed page backlink, preserving the seed, and re-read it. If the backlink update fails, first reconcile a page with the exact construct/reference marker on retry; reuse it rather than creating another. Multiple matching pages or a backlink to a missing/wrong-backend page stop consumption for repair. The locked prefix and explicit page dependencies stay intact. No separate construct completion status is required: no pending reference means fully specified, not all pages merged.

`grimoire-run` reads the document order and reference backlinks instead of querying a milestone. Its Phase 1 invokes `grimoire-spec ac:<UUID>` in order; Phase 2 reads every typed page through the existing GitHub/local backend and follows the existing DAG, ledger, auto-plan, execution and review rules. The ledger records the full `ac:` identity and page backend so resume cannot attach to another construct. `grimoire-run`/`grimoire-execute` do not edit the native document or reference metadata. Optional board progress updates use only native issue status and preserve description/seed: planned/executing → `in_progress`, review → `in_review`, human-confirmed merged/done → `done`. A blocked page remains `in_progress`, with its blocker recorded in the normal page review/ledger; never mark it done because specification finished. `grimoire-adopt` remains for GitHub issues/milestones; native adoption is outside 0.14.1.

## Updating bots

For `grimoire-update`, detect the managed catalog **before** inspecting `.git` or offering a CLI reinstall. Read the version of the **loaded skill body** and its matching distribution; a snapshot VERSION alone does not prove the catalog was updated. Resolve the latest **published release/tag**, not `main/VERSION`, and read that tag's changelog. On the user's update authorization use `update_skill_from_source` for each of the 13 Grimoire names; use `offer_install_skill` only for missing skills or an explicit source change. Do not use `all`, which would update unrelated helpers. A workspace skill is shared: update each catalog entry once, then verify availability and loaded version for each bot using it. Preserve project backend settings and approved repository exceptions; installing a new adapter does not migrate project state.

If the app opens a proposal or installation card, it is pending, not installed. After approval, verify the 13 loaded skills, matching adapter/conventions version and helper/runtime availability for each connected bot; report disconnected bots separately. Start a fresh skill invocation/session to load new text. A failure or pending card is reported per skill/bot, never as an all-bots success. No automatic reconfiguration of GitHub authentication, project backends, existing constructs or dev ports.
