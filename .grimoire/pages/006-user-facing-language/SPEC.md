# 006 — User-Facing Language: English Source Strings + Native-Language Runtime

## Context

Today the plugin's hardcoded operator-facing strings are a mix of English prose and **Portuguese (pt-BR)** literals. The pt-BR literals are concentrated in:

- The `❌` hard-stop messages, defined canonically in `GRIMOIRE-CONVENTIONS.md` `§ Pause-point pattern` and **duplicated verbatim** into the bodies of `grimoire-execute`, `grimoire-plan`, `grimoire-spec`, and `grimoire-construct-update`.
- The `📄` IDE-review example line (`📄 Rascunho aberto…`) in `§ IDE-aware review` and in `grimoire-note`.
- An explicit note in `grimoire-note` (line 60) stating *"Operator-facing message may be pt-BR per project precedent"* — which directly contradicts the desired direction.

This couples the canonical strings to one human language and makes them hard to translate. `PROJECT.md` already aspires to *"All user-facing messages default to English"*, but the actual source strings haven't followed.

This page does two coordinated things:

1. **Normalize every hardcoded operator-facing string in the plugin source to English**, so the strings are clean, translatable templates.
2. **Introduce a single, cross-skill convention**: the source strings are English *templates*; at runtime, every skill renders all terminal communication to the user in the user's **native language**, detected from how the user wrote, with an OS-locale fallback. The English source becomes the canonical translatable string, not the literal terminal output.

## Goals

- Add a new section `§ User-facing language` to `GRIMOIRE-CONVENTIONS.md` as the single source of truth for the runtime-localization behavior, defining:
  - **Source-string rule:** all hardcoded operator-facing strings in skill bodies and the conventions are authored in English.
  - **Runtime-rendering rule:** every skill renders all terminal communication to the user in the user's native language, treating the English source strings as translatable templates.
  - **Detection rule:** primary = the language of the user's input in the current session; fallback = the OS / system locale; final fallback = English when neither is determinable.
  - **Localization boundary:** literal tokens are preserved verbatim — command names (`/grimoire-spec`, etc.), status tokens (`[spec]`/`[planned]`/`[finished]`/`[pending]`/`[specced]`), `NNN`/page identifiers, file paths, and the `❌`/`📄` glyphs. Only the natural-language prose around them is localized.
- Translate **all** existing hardcoded pt-BR operator-facing strings in the plugin source to English (canonical templates):
  - The `❌` hard-stop messages in `GRIMOIRE-CONVENTIONS.md` `§ Pause-point pattern` and their duplicated copies in `grimoire-execute`, `grimoire-plan`, `grimoire-spec`, and `grimoire-construct-update`.
  - The `📄` example lines in `§ IDE-aware review` and `grimoire-note`.
- Remove the contradictory *"Operator-facing message may be pt-BR per project precedent"* note in `grimoire-note`.
- Wire the new section into the `[Required Reading]` block of **all 11 SKILL.md files** so every skill loads the rule.
- Reconcile the `PROJECT.md` wording (line 59 / line 22) so it reflects "English source string, native-language runtime" rather than "messages default to English". *(Mechanism TBD in plan — see Open questions; PROJECT.md is normally written only by `grimoire-init`/`grimoire-note`.)*
- Ship the change: bump `plugin.json` + `marketplace.json` to the next minor version and add a matching `CHANGELOG.md` section.

## Non-goals

- **No translation files / i18n machinery.** There is no source code; localization is performed by the model at runtime from the English source strings. We are not adding `.po`/`.json` locale bundles or a string catalog.
- **No change to non-operator-facing content.** Commit messages, `SPEC.md` / step-file / `CONSTRUCT.md` content, code, and identifiers stay English exactly as today.
- **No new skills, no new pages, no construct.** This is a convention + source-string normalization page.
- **No change to the bilingual READMEs** (`README.md` / `README.pt-BR.md`) as translation artifacts — though the new convention should be mentioned in their skill descriptions if they enumerate behaviors *(plan decides)*.
- **No behavioral change to control flow** — hard-stops still hard-stop, pauses still pause; only the *language* of what is shown changes.

## Scope

Files / surfaces touched:

- `GRIMOIRE-CONVENTIONS.md`:
  - New `§ User-facing language` section.
  - `§ Pause-point pattern` — translate every `❌` string to English.
  - `§ IDE-aware review` — translate the `📄` example line.
- `skills/grimoire-execute/SKILL.md` — translate `❌` strings; add `§ User-facing language` to `[Required Reading]`.
- `skills/grimoire-plan/SKILL.md` — translate `❌` strings; add to `[Required Reading]`.
- `skills/grimoire-spec/SKILL.md` — translate `❌` strings; add to `[Required Reading]`.
- `skills/grimoire-construct-update/SKILL.md` — translate `❌` strings; add to `[Required Reading]`.
- `skills/grimoire-note/SKILL.md` — translate the `📄` example; remove the pt-BR-precedent note; add to `[Required Reading]`.
- `skills/grimoire-init/SKILL.md`, `skills/grimoire-quick/SKILL.md`, `skills/grimoire-know/SKILL.md`, `skills/grimoire-update/SKILL.md`, `skills/grimoire-construct/SKILL.md`, `skills/grimoire-deps/SKILL.md` — add `§ User-facing language` to `[Required Reading]` (no hardcoded pt-BR strings expected, but verify).
- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — version bump (versions must match).
- `CHANGELOG.md` — new version section (Added: `§ User-facing language`; Changed: pt-BR→English normalization, Required-Reading wiring).
- `CLAUDE.md` / `README*.md` — update only if they assert "messages may be pt-BR" or otherwise contradict the new rule *(plan verifies)*.
- `.grimoire/PROJECT.md` — reconcile the language-convention wording *(see Open questions for the write mechanism)*.

## Acceptance criteria

- `GRIMOIRE-CONVENTIONS.md` contains a `§ User-facing language` section defining the source-string rule, the runtime-rendering rule, the detection rule (session-input → OS locale → English), and the localization boundary (literal tokens preserved).
- `grep` for pt-BR operator-facing literals (`não`, `já foi`, `Rode`, `está`, `Rascunho`, `primeiro`, `corrigir`, `aberto`, `seguir`) across `skills/` and `GRIMOIRE-CONVENTIONS.md` returns **no hardcoded user-facing string** (matches only inside this SPEC or genuinely-English contexts are acceptable; the `❌`/`📄` strings are all English).
- Every `❌` hard-stop message keeps its `❌` glyph, the literal command/token references, and identical control-flow meaning — only the prose is now English, and the canonical copy in `§ Pause-point pattern` and the duplicated copies in the four skill bodies are **byte-consistent** with each other.
- The contradictory pt-BR-precedent note in `grimoire-note` is gone.
- All **11** SKILL.md `[Required Reading]` blocks reference `§ User-facing language`.
- `plugin.json` and `marketplace.json` carry the same new version, and `CHANGELOG.md` has a matching section (release workflow precondition).
- No commit message, SPEC, step file, or code identifier was changed to a non-English language as a side effect.

## Constraints

- **Single source of truth:** the localization rule lives only in `GRIMOIRE-CONVENTIONS.md`; SKILL.md bodies reference it and never restate it (per the repo's core convention). The `❌`/`📄` strings remain duplicated where they already are today — this page translates them in place, it does not change the duplication policy.
- **Frontmatter is load-bearing:** do not rename or drop `name`/`description`/`argument-hint` or the `---` delimiters when editing `[Required Reading]`.
- **Preserve substitutions verbatim:** `$ARGUMENTS`, `$1`, `${CLAUDE_PLUGIN_ROOT}`.
- **Release discipline:** `plugin.json` and `marketplace.json` versions must match; the CHANGELOG section must exist before release; the version bump + CHANGELOG entry land in the same change set, not as a follow-up.
- **No TDD applies** (no code/tests in this repo) — verification is by `grep` and review.

## Open questions

- **Version number:** this is an additive behavioral convention plus a non-breaking source normalization → expected `0.12.0` (minor). Confirm at plan time.
- **`PROJECT.md` write mechanism:** the `§ Project context` dual-writer contract says only `grimoire-init`/`grimoire-note` write `PROJECT.md`. Since this is the plugin's own dogfooding repo and the change is a wording reconciliation, the plan should decide whether to (a) fold the `PROJECT.md` edit into this page's execution as a documented exception, or (b) leave a note to run `/grimoire-note` afterward. Lean toward (b) to honor the contract.
- **Exact section ordering** of `§ User-facing language` within `GRIMOIRE-CONVENTIONS.md` (near `§ IDE-aware review` / `§ Pause-point pattern`, since it governs operator-facing output) — plan to decide.

## References

- `GRIMOIRE-CONVENTIONS.md` — `§ Pause-point pattern` (canonical `❌` strings), `§ IDE-aware review` (`📄` example), `§ Project context` (PROJECT.md dual-writer).
- `.grimoire/PROJECT.md` lines 22 & 59 — existing "messages default to English" wording to reconcile.
- pt-BR string inventory (from analysis): `grimoire-execute` L22/24/26/27/35/36; `grimoire-plan` L22/24/26/27/28; `grimoire-spec` L122/125; `grimoire-construct-update` L27/40; `grimoire-note` L60; `GRIMOIRE-CONVENTIONS.md` L297/321–338/344–345.
- `CHANGELOG.md` `[0.11.0]` — format precedent for the new section.
