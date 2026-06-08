# 005 — grimoire-construct-update skill

## Context

The `construct` artifact (page 004) gave Grimoire a larger-than-a-page objective container: `.grimoire/constructs/NNN-<name>/` holding a `CONSTRUCT.md` checklist plus an ordered `references/N-<short-name>.md` folder of reference-seeds. Today the **only** way to touch construct content is `grimoire-construct`, which *authors* a construct from scratch; the only other allowed edit is `grimoire-spec` flipping a single reference `[pending]` → `[specced]` on consumption. There is no supported, disciplined way to **alter an existing construct** — add a reference you discovered mid-flight, drop one that became irrelevant, reorder the remaining work, refine a seed's detail, retitle the objective, or rename the construct.

This page adds a new orthogonal skill, **`grimoire-construct-update`**, the second authorized writer of construct files. It alters an *existing* construct in place — never creating one (that stays `grimoire-construct`'s job) and never spawning a page or touching `HISTORIC.md`/`PROJECT.md`. It is the construct analog of `grimoire-note`: a surgical, incremental editor for an artifact another skill originally authored.

The governing safety rule comes from how constructs are consumed: `grimoire-spec` always consumes the **lowest-numbered `[pending]`** reference. That makes `[specced]` references an **immutable leading prefix** (`1..k` specced, `k+1..n` pending). The skill treats that prefix as locked, so every spawned page stays traceable and never orphaned.

## Goals

- Add a new skill `skills/grimoire-construct-update/SKILL.md` (frontmatter `name` / `description` / `argument-hint` + prompt body) that alters an existing construct in place.
- Support four alteration families, all confined to the `[pending]` tail (or construct-level metadata):
  - **Structural** — add reference(s) (append, or insert at a position in the pending tail), remove reference(s), reorder references.
  - **Edit reference detail** — refine a `[pending]` reference's `references/N-<short-name>.md` body and its one-line `CONSTRUCT.md` checklist entry.
  - **Edit construct intro/objective** — rewrite the `CONSTRUCT.md` header/intro/arc (not the reference list).
  - **Rename the construct** — change the `<name>` of `.grimoire/constructs/NNN-<name>/` (and internal self-references), preserving `NNN`.
- Enforce the **locked `[specced]` prefix** invariant: `[specced]` references cannot be edited, removed, or reordered, and no new reference may be inserted ahead of a `[specced]` one. Attempts are refused with a clear message naming the reference and its backlinked page.
- Enforce **contiguous renumbering of the pending tail**: after any structural change, `references/N-*.md` files and the `CONSTRUCT.md` checklist are renumbered to stay contiguous and in execution order. The specced prefix never moves, so its file numbers and page backlinks are never disturbed.
- Resolve the target construct from the input (by `NNN` number or `<name>`); hard-stop if it does not exist.
- Run any needed codebase/external research inside sub-agent(s) (for add/edit operations) so the orchestrator stays lucid; the orchestrator interviews, resolves the operation set, and performs the writes.
- IDE-aware draft review of the altered `CONSTRUCT.md` and affected `references/` files before finalizing; pause for approval.
- End with a single `docs(grimoire): update construct <name>` commit covering only the altered construct files (including any renames).
- Amend `GRIMOIRE-CONVENTIONS.md` to make these rules the single source of truth, and update `CLAUDE.md`, `README.md`, `README.pt-BR.md`, `CHANGELOG.md`, and the version (`plugin.json` + `marketplace.json`).

## Non-goals

- **Not** creating a construct from scratch — that remains `grimoire-construct`. This skill hard-stops if the target construct does not already exist.
- **Not** editing, removing, reordering, or inserting ahead of `[specced]` references (the locked-prefix rule). Re-shaping already-spawned work is out of scope; the user edits the spawned page instead.
- **Not** spawning a page, writing `SPEC.md`, or touching `HISTORIC.md` — the construct stays self-contained; only its spawned pages hit `HISTORIC.md`.
- **Not** writing `.grimoire/PROJECT.md` (the dual-writer contract keeps that to `grimoire-init` / `grimoire-note`).
- **Not** changing a construct's `NNN` (the independent construct counter is stable; only `<name>` may change on rename).
- **Not** out-of-order or partial construct consumption, and no change to how `grimoire-spec` consumes references.
- **Not** nested constructs or sub-references — constructs stay flat and self-contained per `§ Construct`.

## Scope

**New file:**
- `skills/grimoire-construct-update/SKILL.md` — the skill body. Phases (proposed): Required Reading → target-construct resolution (hard-stop if missing) → optional research sub-agent(s) → clarifying questions / operation selection → compose altered files + IDE-aware draft review → finalize → commit → closing. Mirrors `grimoire-construct`'s structure and orthogonal-skill guardrails; references `§ Construct` rather than restating rules.

**`GRIMOIRE-CONVENTIONS.md` amendments:**
- `§ Construct` — extend the **writer contract** to name `grimoire-construct-update` as the second authorized author/rewriter of construct files (alters existing constructs only; never creates one; `[specced]` prefix locked). Add an **"Alteration rules"** subsection: the locked-`[specced]`-prefix invariant, the permitted operations, the contiguous-renumber-of-pending-tail policy (specced prefix never renumbers; pending refs carry empty backlinks so backlink rewrites never fire in practice), the rename-preserves-`NNN` rule, and the resolution/hard-stop behavior.
- `§ Commits` — add the `docs(grimoire): update construct <name>` line (single atomic commit covering the altered construct files and any rename).
- `§ Sub-agent spawning` — add a `grimoire-construct-update` clause (research for add/edit runs in sub-agent(s); the orchestrator interviews, resolves operations, and writes).
- `§ Pause-point pattern` — add `grimoire-construct-update` pauses: target-construct-resolution hard-stop (`❌ Construct NNN não existe. Rode /grimoire-construct primeiro.`), the locked-`[specced]`-operation refusal message, clarifying-questions/operation-selection pause, and draft-review pause.

**Doc / manifest updates:**
- `CLAUDE.md` — add the `grimoire-construct-update` bullet to the skills enumeration, bump the skill count (ten → eleven), and list it where `§ Construct`-dependent skills are referenced.
- `README.md` + `README.pt-BR.md` — add the skill to the skill list/table.
- `CHANGELOG.md` — new version section describing the skill.
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — bump version in lockstep (proposed `0.10.0` → `0.11.0`), CI enforces they match.

**Explicitly untouched:** `.grimoire/PROJECT.md`, `HISTORIC.md` (beyond this page's own `grimoire-spec` registration), `grimoire-construct`'s authoring path, and `grimoire-spec`'s consumption path.

## Acceptance criteria

- `skills/grimoire-construct-update/SKILL.md` exists with valid frontmatter (`name: grimoire-construct-update`, a `description`, an `argument-hint`) and a phased body that references `GRIMOIRE-CONVENTIONS.md` via `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md` and does not restate `§ Construct` rules.
- Invoking the skill against an **existing** construct and requesting any supported operation produces the correct in-place edits: structural changes confined to the pending tail, contiguous renumbering of `references/N-*.md` + checklist, untouched specced prefix and its backlinks, and (for rename) a renamed folder with `NNN` preserved.
- Requesting an edit/removal/reorder of a `[specced]` reference, or an insertion ahead of one, is **refused** with a message naming the reference and its page backlink — no files changed.
- Invoking against a **non-existent** construct hard-stops with `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` and creates/changes nothing.
- The skill never writes `HISTORIC.md`, never writes `PROJECT.md`, never creates a page folder, and never creates a new construct.
- The run ends with exactly one `docs(grimoire): update construct <name>` commit scoped to the altered construct files (and any rename); no page-state commits.
- The draft review follows `§ IDE-aware review` (write-to-disk + pause in IDE mode; inline fallback otherwise).
- `GRIMOIRE-CONVENTIONS.md` is the single source of truth for every rule above; the `§ Construct` writer contract, an Alteration-rules subsection, `§ Commits`, `§ Sub-agent spawning`, and `§ Pause-point pattern` all reflect the new skill.
- `CLAUDE.md`, `README.md`, `README.pt-BR.md`, and `CHANGELOG.md` list the new skill; `plugin.json` and `marketplace.json` carry the same bumped version with a matching CHANGELOG section.

## Constraints

- **Markdown/JSON only** — no source code, no tests; edits land in prompt text and manifest files. `§ TDD` does not apply (this page produces skill prose + conventions, not code).
- **Single source of truth** — load-bearing rules live only in `GRIMOIRE-CONVENTIONS.md`; the SKILL.md body references them and never restates them.
- **Orthogonal-skill discipline** — same family as `grimoire-init` / `grimoire-note` / `grimoire-know` / `grimoire-update` / `grimoire-deps` / `grimoire-construct`: never creates a page, never writes `HISTORIC.md` or `PROJECT.md`.
- **Conventional Commits in English**; operator-facing messages may be pt-BR per project precedent, but construct content and commit messages stay English.
- **Frontmatter is load-bearing** — `name` / `description` / `argument-hint` and the `---` delimiters must be intact; `$ARGUMENTS` / `$1` preserved verbatim.
- **Version lockstep** — `plugin.json` and `marketplace.json` versions must match and the CHANGELOG must already carry the new version's section (release CI fails otherwise).
- **Locked-prefix safety is the dominant property** — like the worktree-teardown invariant for parallel execute, the never-touch-a-specced-reference rule is non-negotiable; it is what keeps every spawned page traceable.

## Open questions

- None blocking. (Decided during spec: all four operation families in scope; `[specced]` refs locked; contiguous renumbering of the pending tail; name `grimoire-construct-update` with commit `docs(grimoire): update construct <name>`.) Whether the version bump is `0.11.0` vs another increment is a release-time detail for `grimoire-plan`/execution to confirm against the latest `main`.

## References

- `GRIMOIRE-CONVENTIONS.md` `§ Construct` (writer contract, consumption rules, self-containment), `§ Commits`, `§ Sub-agent spawning`, `§ Pause-point pattern`, `§ .grimoire/ layout`, `§ IDE-aware review`.
- `skills/grimoire-construct/SKILL.md` — the authoring counterpart and structural template for this skill.
- `skills/grimoire-note/SKILL.md` — precedent for a surgical, incremental editor of an artifact another skill authored.
- `skills/grimoire-spec/SKILL.md` Phase C — the consumption path whose lowest-pending-first rule establishes the locked-prefix invariant.
- Page `004-construct-concept` (`.grimoire/HISTORIC.md`) — introduced the construct artifact this page extends.
