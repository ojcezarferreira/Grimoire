# Managed-workspace acceptance matrix

`scripts/test-contracts.py` checks distribution consistency offline. It does not run an LLM, emulate platform tools, or prove the behaviors below. A published release must be loaded from its actual catalog source before the managed rollout can be called verified. Keep real tool-returned IDs/versions and findings with the rollout record; do not report a pending card as applied.

## Bootstrap and transport

| Scenario | Expected behavior |
|---|---|
| Raw catalog import; unresolved home token; no global config | Read adapter/conventions/config defaults/deps from one matching immutable release; use project overrides. No CLI installer or guessed path. |
| Installed skill differs from shared snapshot VERSION | Reject that snapshot; fetch the matching source. Failure reading required source files stops with the missing file. |
| Authenticated GitHub connector; no `gh` | Repository read verifies GitHub page transport. No login/token request. Discover the operations this skill needs. |
| Issue/PR connector without milestones | GitHub pages remain available. Native constructs use no milestone call/field. An explicit GitHub construct choice reports the missing capability without changing existing state. |
| App permissions gate PR readiness / publication | Preserve draft/prepared work, request the actual action approval, wait. Autonomous skill text does not bypass it. |
| Project prohibits worktrees or uses restricted branch prefix | Init prepares the exact exception and allowed prefix for approval; update preserves existing choices. No unauthorized worktree or branch. |

## Native construct lifecycle

Use a disposable construct with three references, a stable project key, and an authorized audience. Do not send production credentials or data. Exercise with local pages and then with GitHub pages in a test repository; preserve the resulting tool evidence separately from these expected outcomes.

| Scenario | Expected behavior |
|---|---|
| Create | Read back one document + three assigned native issues with consistent construct/reference markers, stable IDs and ordered links. No local construct or milestone. |
| Serial / parallel references | All dependencies absent → implicit chain. Explicit empty dependencies → independent roots. Dangling/forward targets and cycles fail validation before writes. |
| Expand first seed | Full spec interview; one new page in chosen page backend; native reference becomes specced with a typed backlink; seed preserved. |
| Native GitHub page | New GitHub page marker carries `construct=ac:<UUID>` / `reference=ref-N` and translated issue dependencies. No native issue number reused as a GitHub number; no milestone field. |
| Native local page | Local SPEC carries the native construct and stable reference IDs, plus translated local page dependencies. |
| Edit/reorder pending tail | Specified prefix and backlinks unchanged. Stable reference IDs and graph targets survive reorder. |
| Edit/remove/reorder specified seed or insert before it | Refusal identifies reference and page; no writes. |
| Remove pending seed | Cancel native issue; remove membership and dependency edges; never reuse its ID on a later add. |
| Create succeeds; response/index write fails | Read/reconcile matching objects before retry. Resume incomplete creation; no duplicate tasks/documents and no deleted handoff brief before success. |
| Page succeeds; native backlink write fails | Locate page by exact construct/reference marker and reuse it. Multiple matches stop for repair. |
| Missing/wrong-parent task, corrupt list, duplicate title or wrong repository | Stop with concrete conflicting objects. No guessed member or new construct. Explicit `ac:` resolves a unique identity. |
| Concurrent mutation between read and write | Re-read/reconcile; re-review material changes. Serialize writers; never claim atomicity without CAS/lock support. |
| Run/resume | Native order/backlinks select pages, normal page DAG determines waves. Native ledger key has no colon and records the full identity/backend. Execution leaves construct content untouched. |
| Board state differs from reference metadata | Metadata determines pending/specced; page backend determines execution status. Spec completion never projects a merged/done task. |
| DM-created construct accessed by another bot | Honor actual visibility and request the needed access handoff. Never copy private seeds into a broader channel. |

## Rollout

After release approval/publication, update each of the 13 Grimoire catalog entries from its recorded source once. Verify the loaded body and pinned distribution version for each connected bot. Audit all four helper skills and browser executable/runtime separately. Record failed/pending entries explicitly, keep project configs and existing constructs intact, and repeat the affected lifecycle cases if the loaded text changes.
