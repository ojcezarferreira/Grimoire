# Step 4 — Release: version bump + CHANGELOG section + final verification

**Prerequisite:** Steps 1–3 are complete (convention added, strings translated, Required Reading wired). This step ships the change.

No TDD applies. Follow `§ Commits`.

## 4a — Version bump to `0.12.0`

Confirmed at plan time: this is an additive behavioral convention + non-breaking source normalization → minor bump.

- `.claude-plugin/plugin.json`: `"version": "0.11.0"` → `"version": "0.12.0"`.
- `.claude-plugin/marketplace.json`: `"version": "0.11.0"` → `"version": "0.12.0"`.

The two versions **must match** (CI enforces it).

## 4b — CHANGELOG section

Add a new `## [0.12.0] — 2026-06-16` section at the top of the version list in `CHANGELOG.md` (directly above `## [0.11.0]`), following the existing Keep-a-Changelog format. Suggested content:

```markdown
## [0.12.0] — 2026-06-16

### Added
- New `GRIMOIRE-CONVENTIONS.md` `§ User-facing language` convention: hardcoded operator-facing strings are authored in English (canonical translatable templates), but every skill renders terminal communication in the user's native language at runtime — detected from the user's session input, falling back to the OS/system locale, then to English. Literal tokens (command names, status tokens, `NNN`/page identifiers, file paths, and the `❌`/`📄` glyphs) are preserved verbatim; only the surrounding prose is localized. The section is wired into the `[Required Reading]` block of all 11 skills.

### Changed
- Normalized every hardcoded operator-facing pt-BR string in the plugin source to English: the `❌` hard-stop messages in `§ Pause-point pattern` and their duplicated copies in `grimoire-execute`, `grimoire-plan`, `grimoire-spec`, and `grimoire-construct-update`; and the `📄` IDE-review example lines in `§ IDE-aware review` and `grimoire-note`. The canonical and duplicated copies stay byte-consistent.
- Removed the contradictory "operator-facing message may be pt-BR per project precedent" notes from `grimoire-note`, `grimoire-construct`, and `grimoire-construct-update`; those bodies now defer to `§ User-facing language`.
```

(Keep the wording aligned with the actual edits made in Steps 1–3; adjust if any detail diverged.)

## 4c — Final verification (acceptance criteria)

Run and confirm all green:
- `grep -m1 '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json` → both `0.12.0`.
- `grep -q "## \[0.12.0\]" CHANGELOG.md` → present.
- `grep -rnE "não|já foi|Rode|está|Rascunho|primeiro|corrigir|aberto|seguir|may be pt-BR|pt-BR is permitted" skills/ GRIMOIRE-CONVENTIONS.md` → no operator-facing pt-BR literal remains.
- `grep -rl "§ User-facing language" skills/*/SKILL.md | wc -l` → `11`.
- `git log --oneline -n 5` shows the per-step commits; no commit message, SPEC, step file, or code identifier was switched to a non-English language as a side effect.

## 4d — Commit

`docs(grimoire): release 0.12.0 with user-facing-language convention`

Cover `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `CHANGELOG.md`.

## 4e — `PROJECT.md` reconciliation reminder (do NOT edit `PROJECT.md`)

Per the `§ Project context` dual-writer contract, only `grimoire-init`/`grimoire-note` may write `.grimoire/PROJECT.md`. This page deliberately does **not** edit it (open-question option (b), confirmed at plan time). After this step, remind the user:

> The new `§ User-facing language` convention supersedes the "messages default to English" wording in `.grimoire/PROJECT.md` (lines ~22 and ~59). Run `/grimoire-note "user-facing strings are English source, rendered in the user's native language at runtime"` to reconcile the project context.
