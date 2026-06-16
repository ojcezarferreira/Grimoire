# Step 1 — `GRIMOIRE-CONVENTIONS.md`: new `§ User-facing language` section + English `❌`/`📄` canonical strings

**Goal of this step:** make `GRIMOIRE-CONVENTIONS.md` the single source of truth for the new behavior and the English canonical strings. This step establishes the *canonical* English `❌`/`📄` strings; Step 2 copies them byte-for-byte into the four skill bodies, so accuracy here is load-bearing.

Touches **only** `GRIMOIRE-CONVENTIONS.md`. Do not edit any `skills/*` file in this step.

No TDD applies (no code/tests in this repo). Verification is by `grep` + review. Follow `§ Commits`.

## 1a — Add the new `§ User-facing language` section

Insert a new section **immediately before `## § Pause-point pattern`** (i.e., right after the end of `## § IDE-aware review`), separated by the existing `---` horizontal-rule convention used between sections. Use this exact content:

```markdown
## § User-facing language

Grimoire's hardcoded operator-facing strings are authored in English, but what the user actually sees in the terminal is rendered in the user's own language. The English source is a translatable template, not the literal output.

- **Source-string rule.** Every hardcoded operator-facing string in a skill body or in this conventions file is written in English. This includes the `❌` hard-stop messages, the `📄` IDE-review lines, and any other prose addressed to the operator.
- **Runtime-rendering rule.** When a skill communicates with the user, it renders all natural-language prose in the user's native language, treating the English source string as a template to translate. This applies to every skill and to every operator-facing message — hard-stops, pauses, clarifying questions, summaries, and status lines alike.
- **Detection rule.** Determine the user's language in this order: (1) the language the user wrote in during the current session — the primary signal; (2) the OS / system locale, when the session input is insufficient to tell; (3) English, as the final fallback when neither is determinable.
- **Localization boundary.** Localize only the natural-language prose. Preserve verbatim: command names (`/grimoire-spec`, `/grimoire-plan`, …), status tokens (`[spec]`, `[planned]`, `[finished]`, `[pending]`, `[specced]`), page/identifier placeholders (`NNN`, page names), file paths, and the `❌` / `📄` glyphs. A localized message keeps the same glyph, the same literal tokens, and the same control-flow meaning — only the surrounding prose changes language.
- **Non-operator-facing content stays English.** Commit messages, `SPEC.md` / step-file / `CONSTRUCT.md` content, code, and identifiers are always English regardless of the user's language (see `§ Commits`).
```

## 1b — Translate the `📄` example in `§ IDE-aware review`

In `## § IDE-aware review`, step 2 of the IDE-aware flow, replace the pt-BR example line:

`📄 Rascunho aberto em .grimoire/PROJECT.md — revise no editor e diga "ok" para seguir, ou liste mudanças.`

with the canonical English:

`📄 Draft opened at .grimoire/PROJECT.md — review it in the editor and say "ok" to proceed, or list changes.`

Keep the `📄` glyph, the path, and the surrounding sentence structure intact — only the prose changes.

## 1c — Translate every `❌` string in `§ Pause-point pattern`

Translate the hard-stop messages in `## § Pause-point pattern` to English, preserving each `❌` glyph, every literal token (`NNN`, command names, `depends-on`, page numbers), and the exact control-flow meaning. Use this canonical mapping (the **left** side is what's in the file today; replace with the **right** side verbatim):

| pt-BR (current) | English (canonical) |
| --- | --- |
| `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` | `❌ Construct NNN does not exist. Run /grimoire-construct first.` |
| `❌ Construct NNN já foi totalmente especificado.` | `❌ Construct NNN has already been fully specified.` |
| `❌ Page NNN não existe. Rode /grimoire-spec primeiro.` | `❌ Page NNN does not exist. Run /grimoire-spec first.` |
| `❌ Page NNN não tem SPEC.md. Rode /grimoire-spec primeiro.` | `❌ Page NNN has no SPEC.md. Run /grimoire-spec first.` |
| `❌ Page NNN já foi planejada.` | `❌ Page NNN has already been planned.` |
| `❌ Page NNN já foi finalizada.` | `❌ Page NNN has already been finished.` |
| `❌ Page NNN não está registrada no HISTORIC. Rode /grimoire-spec primeiro.` | `❌ Page NNN is not registered in HISTORIC. Run /grimoire-spec first.` |
| `❌ Page NNN não existe.` (execute precondition) | `❌ Page NNN does not exist.` |
| `❌ Page NNN ainda não tem plano. Rode /grimoire-plan NNN primeiro.` | `❌ Page NNN has no plan yet. Run /grimoire-plan NNN first.` |
| `❌ Page NNN ainda está em spec. Rode /grimoire-plan NNN primeiro.` | `❌ Page NNN is still in spec. Run /grimoire-plan NNN first.` |
| `❌ Page NNN tem dependências cíclicas entre steps. Rode /grimoire-plan NNN para corrigir.` | `❌ Page NNN has cyclic dependencies between steps. Run /grimoire-plan NNN to fix.` |
| `❌ Page NNN referencia um step inexistente em depends-on. Rode /grimoire-plan NNN para corrigir.` | `❌ Page NNN references a non-existent step in depends-on. Run /grimoire-plan NNN to fix.` |
| `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` (construct-update resolution) | `❌ Construct NNN does not exist. Run /grimoire-construct first.` |
| `❌ Reference 2 já foi especificada (page 007) — não pode ser editada, removida ou reordenada.` | `❌ Reference 2 has already been specified (page 007) — it cannot be edited, removed, or reordered.` |

Note: the two `❌ Construct NNN does not exist…` occurrences (consumption hard-stop and construct-update resolution) must be **byte-identical** to each other.

## 1d — Verify

- `grep -nE "não|já foi|Rode|está|Rascunho|primeiro|corrigir|aberto|seguir" GRIMOIRE-CONVENTIONS.md` returns **nothing** (all operator-facing prose is now English).
- The new `## § User-facing language` section sits between `§ IDE-aware review` and `§ Pause-point pattern`.

## 1e — Commit

`docs(grimoire): add user-facing-language convention and english hard-stop strings`

Cover only `GRIMOIRE-CONVENTIONS.md` in this commit. Do **not** touch `HISTORIC.md` (that is Phase 5/6 of the planner-level run, handled by the orchestrator after all steps).
