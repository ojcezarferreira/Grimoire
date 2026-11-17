---
name: grimoire-quick
description: Quick task or bug fix with Grimoire — scope gatekeeper, an inline plan you authorize, then one quick sub-agent fixes it with TDD and atomic commits on your current branch. No page is created.
argument-hint: Task/fix description
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ TDD`, `§ Code comments`, `§ Sub-agent spawning` (the `quick` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation` (read-only consumption), `§ Skill composition`, `§ Commits`, `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ Backends`, `§ .grimoire/ layout` (pages), `§ Construct`, `§ Parallel execution`, `§ Review loop`, `§ Run`. **Note:** quick is fully ephemeral — it never creates a page (no issue, no page folder), and its commits land on the user's current branch (no page branch, no worktree, no PR). The only file it may touch outside the actual fix is the ephemeral plan draft at `.grimoire/bag/drafts/quick-plan-<epoch>.md` in IDE mode (`§ IDE-aware review`), removed before the skill ends.
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and any other linked doc the fix touches. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` once this task is complete (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice) — the `quick` role's model and effort.
4. Backend detection is skipped per `§ Backends` (who detects) — this skill never reads or writes pages, constructs, or PRs.

**[Objective]**
I need you to quickly resolve the following minor adjustment or bug fix:

$ARGUMENTS

**[Phase 1: Analysis & Scope Gatekeeper]**
- Analyze the relevant codebase architecture for this specific request.
- Evaluate the complexity and scope of the requested change.
- **CRITICAL — SCOPE CHECK** (per `§ Pause-point pattern`, `grimoire-quick`: scope gatekeeper): if this request is too large, complex, or risks context degradation, you MUST STOP immediately. Do not generate a plan. Inform me with the following message: *"This task is too large for a quick execution. Please start a new session and run `/grimoire-spec` to open a page in the long-form Spec → Plan → Execute pipeline."*

**[Phase 2: Quick Planning & User Authorization]**
- If the scope is confirmed as small and safe for quick execution, perform the final clarity check per `§ Pause-point pattern` (`grimoire-quick`: final clarity check): self-review the intended fix and, if any expected-behavior detail, file-scope question, error-handling choice, or naming decision is still based on a silent assumption, PAUSE and ask the user with the question tooling of `§ Harness adaptation` before composing the plan draft. Only continue to the next bullet once the fix is fully unambiguous.
- Present a clear, step-by-step execution plan for my review per `§ IDE-aware review`:
  - **IDE detected:** create `.grimoire/bag/drafts/` if it does not exist, then write the plan to `.grimoire/bag/drafts/quick-plan-<epoch>.md` so the IDE renders it. Generate `<epoch>` with `date +%s` at the moment of writing and memorize the full path — it will be reused in Phase 5 and in the abandonment branch below. Tell me in one short line that the plan is open in the editor.
  - **Terminal-only fallback:** output the plan directly in our chat.
- Pause per `§ Pause-point pattern` (`grimoire-quick`: plan authorization): wait for my explicit authorization or corrections before proceeding. Do NOT start coding or spawning agents yet. If I abandon the plan, delete the memorized `.grimoire/bag/drafts/quick-plan-<epoch>.md` (IDE mode only) and end the skill.

**[Phase 3: Execution]**
- Once I authorize the plan, spawn one sub-agent in the `quick` role per `§ Sub-agent spawning` (one sub-agent for the whole fix), with the model and effort of that role (`§ Configuration`) and the docs pointers of `[Required Reading]` step 2.
- Instruct the sub-agent to execute the approved plan step-by-step per `§ TDD` and `§ Code comments`, in the user's working tree on the current branch. On Codex the prompt begins with `cd <repo root>` — sub-agents inherit no working directory (the Codex deltas of `§ Harness adaptation`).

**[Phase 4: Version Control]**
- Instruct the sub-agent to make commits per `§ Commits`.

**[Phase 5: Cleanup]**
- If Phase 2 wrote the memorized `.grimoire/bag/drafts/quick-plan-<epoch>.md` (IDE mode), delete that exact path now. The draft is ephemeral and must not survive past the skill's run. The fix commits stay; the plan draft does not.
- If `.grimoire/PROJECT.md` was missing, remind the user that running `grimoire-init` once gives future sessions richer context.
