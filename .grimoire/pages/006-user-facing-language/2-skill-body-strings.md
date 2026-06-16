# Step 2 — Translate hardcoded `❌`/`📄` strings in skill bodies; remove pt-BR-precedent notes

**Prerequisite:** Step 1 is complete — `GRIMOIRE-CONVENTIONS.md` now carries the canonical English `❌`/`📄` strings and the new `§ User-facing language` section. This step makes the **duplicated copies** in the skill bodies byte-consistent with those canonical strings, and removes the notes that contradict the new convention.

Before editing, re-read the now-English `§ Pause-point pattern` and `§ IDE-aware review` in `GRIMOIRE-CONVENTIONS.md` and copy each `❌`/`📄` string **verbatim** so the skill-body copy is byte-identical to the canonical copy.

No TDD applies. Verification is by `grep` + review. Follow `§ Commits`. Do **not** edit `[Required Reading]` blocks in this step — that is Step 3. Do **not** touch version files / CHANGELOG — that is Step 4.

## 2a — `skills/grimoire-execute/SKILL.md` (`❌` strings)

Translate, byte-consistent with `§ Pause-point pattern`:
- L22: `❌ Page NNN não existe.` → `❌ Page NNN does not exist.`
- L24: `❌ Page NNN ainda não tem plano. Rode /grimoire-plan NNN primeiro.` → `❌ Page NNN has no plan yet. Run /grimoire-plan NNN first.`
- L27: `❌ Page NNN já foi finalizada.` → `❌ Page NNN has already been finished.`
- L35: `❌ Page NNN tem dependências cíclicas entre steps. Rode /grimoire-plan NNN para corrigir.` → `❌ Page NNN has cyclic dependencies between steps. Run /grimoire-plan NNN to fix.`
- L36: `❌ Page NNN referencia um step inexistente em depends-on. Rode /grimoire-plan NNN para corrigir.` → `❌ Page NNN references a non-existent step in depends-on. Run /grimoire-plan NNN to fix.`

(Also translate any `[spec]`-status hard-stop line present — `❌ Page NNN ainda está em spec…` → `❌ Page NNN is still in spec. Run /grimoire-plan NNN first.` — if it appears in the body.)

## 2b — `skills/grimoire-plan/SKILL.md` (`❌` strings)

Translate, byte-consistent with `§ Pause-point pattern` — including any `❌` strings in the Phase-1 precondition block as well as L27/L28:
- `❌ Page NNN não existe. Rode /grimoire-spec primeiro.` → `❌ Page NNN does not exist. Run /grimoire-spec first.`
- `❌ Page NNN não tem SPEC.md. Rode /grimoire-spec primeiro.` → `❌ Page NNN has no SPEC.md. Run /grimoire-spec first.`
- `❌ Page NNN não está registrada no HISTORIC. Rode /grimoire-spec primeiro.` → `❌ Page NNN is not registered in HISTORIC. Run /grimoire-spec first.`
- L27: `❌ Page NNN já foi planejada.` → `❌ Page NNN has already been planned.`
- L28: `❌ Page NNN já foi finalizada.` → `❌ Page NNN has already been finished.`

## 2c — `skills/grimoire-spec/SKILL.md` (`❌` strings)

Translate the construct-consumption hard-stops (around L122/L125), byte-consistent with `§ Pause-point pattern`:
- `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` → `❌ Construct NNN does not exist. Run /grimoire-construct first.`
- `❌ Construct NNN já foi totalmente especificado.` → `❌ Construct NNN has already been fully specified.`

## 2d — `skills/grimoire-construct-update/SKILL.md` (`❌` strings + pt-BR-precedent notes)

Translate the `❌` strings, byte-consistent with `§ Pause-point pattern`:
- L27: `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` → `❌ Construct NNN does not exist. Run /grimoire-construct first.`
- L40: `❌ Reference 2 já foi especificada (page 007) — não pode ser editada, removida ou reordenada.` → `❌ Reference 2 has already been specified (page 007) — it cannot be edited, removed, or reordered.`

Remove the contradictory pt-BR-permission language (found during planning; in scope per the page goal of eliminating contradictions with `§ User-facing language`):
- L52: drop the parenthetical `(operator-facing message may be pt-BR per project precedent)` from the IDE-detected bullet — the surrounding instruction stays.
- L69: the bullet `Operator-facing messages default to English; pt-BR is permitted per project precedent (existing skills' hard-stop messages). Construct content and commit messages stay English.` — replace with a sentence that defers to the new convention, e.g.: `Operator-facing prose follows ` + "`§ User-facing language`" + ` (English source strings, rendered in the user's native language at runtime). Construct content and commit messages stay English.`

## 2e — `skills/grimoire-note/SKILL.md` (`📄` example + pt-BR-precedent note)

On L60:
- Translate the `📄` example: `📄 PROJECT.md atualizado em .grimoire/PROJECT.md — revise no editor e diga "ok" para seguir, ou liste mudanças.` → `📄 PROJECT.md updated at .grimoire/PROJECT.md — review it in the editor and say "ok" to proceed, or list changes.`
- Remove the contradictory trailing note `(Operator-facing message may be pt-BR per project precedent.)` entirely (per SPEC Goal).

## 2f — `skills/grimoire-construct/SKILL.md` (pt-BR-precedent notes — scope gap found at plan time)

Not in the SPEC's original inventory but in scope per the page goal:
- L43: drop the parenthetical `(operator-facing message may be pt-BR per project precedent)` from the IDE-detected bullet — the surrounding instruction stays.
- L64: the bullet `Operator-facing messages default to English; pt-BR is permitted per project precedent. Construct content and commit messages stay English.` — replace with a sentence deferring to the new convention, mirroring 2d/L69: `Operator-facing prose follows ` + "`§ User-facing language`" + ` (English source strings, rendered in the user's native language at runtime). Construct content and commit messages stay English.`

## 2g — Verify

- `grep -rnE "não|já foi|Rode|está|Rascunho|primeiro|corrigir|aberto|seguir|may be pt-BR|pt-BR is permitted" skills/` returns **no** operator-facing pt-BR literal (matches that are genuinely English context, e.g. the token `pt-BR` inside `README.pt-BR.md` filenames or bilingual-doc references, are fine — but the permission notes above must be gone).
- Every translated `❌`/`📄` string is byte-identical to its canonical copy in `GRIMOIRE-CONVENTIONS.md`.
- No `name`/`description`/`argument-hint` frontmatter or `---` delimiter was disturbed; `$ARGUMENTS`, `$1`, `${CLAUDE_PLUGIN_ROOT}` preserved verbatim.

## 2h — Commit

`docs(grimoire): translate skill-body hard-stop strings to english`

Cover only the `skills/*/SKILL.md` files edited in this step.
