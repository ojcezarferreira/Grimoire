---
name: grimoire-update
description: Update the Grimoire installation to its latest version — reads the installed VERSION, fetches the latest VERSION and CHANGELOG from GitHub, shows the changelog delta, and on your ok runs the Grimoire installer to fetch, check out, and re-copy the skills (a development checkout gets git pull + ./install.sh advice instead).
argument-hint: (no arguments)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Harness adaptation` (install location, `${GRIMOIRE_HOME}`, the "fetch a URL" row), `§ IDE-aware review` (the changelog draft), `§ User-facing language`, `§ Pause-point pattern` (`grimoire-update`: changelog review), `§ Skill composition`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Sub-agent spawning` (this skill spawns nothing), `§ Commits` (this skill commits **nothing**), `§ Backends`, `§ .grimoire/ layout` (pages), `§ Construct`, `§ Parallel execution`, `§ Review loop`, `§ Run`.
2. `.grimoire/PROJECT.md` and `docs/` are not read — this skill maintains the Grimoire installation, not the project; it is exempt from the `grimoire-init` reminder (`§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` only for the one-line `session` notice.
4. Backend detection is skipped per `§ Backends` (who detects) — this skill never reads or writes pages, constructs, or PRs.

**[Objective]**
Update the Grimoire installation on this machine — the home `${GRIMOIRE_HOME}` and the skill copies of `§ Harness adaptation` — to the latest published version. The skill reads the installed version, compares it to the latest on GitHub, shows what changed, and, once authorized, **runs the Grimoire installer itself**; the installer owns every write to the home and to the skill directories. The flow is the same on Claude Code and Codex. The only file the skill may write in the current project is the ephemeral changelog draft `.grimoire/bag/drafts/grimoire-update-changelog-<epoch>.md` (IDE mode), removed before the skill ends.

**[Phase 1: Read installed version]**
- Read `${GRIMOIRE_HOME}/VERSION` (one line, whitespace trimmed).
- Report to the user: `Installed Grimoire version: X.Y.Z`.
- If the file is missing or empty, stop and tell the user the installation is unreadable — they should reinstall Grimoire with `curl -fsSL https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/install.sh | sh`. Do not proceed.

**[Phase 2: Detect the install kind]**
- Run `git -C "${GRIMOIRE_HOME}" config --get grimoire.managed` through the shell.
  - Prints `true` → a **managed clone** made by the installer: Phase 7 runs the installer.
  - Anything else (no output, an error, no `.git`) → a **development checkout** — the installer's dev mode: Phase 5 prints the dev-mode notice instead.

**[Phase 3: Fetch latest version]**
- Fetch `https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/VERSION` per the "fetch a URL" row of `§ Harness adaptation` and trim it.
- If the request fails (network, repo moved, 404), stop and tell the user the latest version could not be determined and ask them to retry later. Do **not** assume Grimoire is up to date and do **not** run the installer.

**[Phase 4: Compare versions]**
- Compare the installed version (Phase 1) to the latest (Phase 3) as strings.
- **If equal:** print `Grimoire is already up to date (X.Y.Z). Nothing to do.` and end the skill — no pause.
- **If different:** continue.

**[Phase 5: Development checkout]** — only when Phase 2 found a development checkout
- Print the notice and STOP — nothing is run, nothing is paused:

  > `${GRIMOIRE_HOME}` is a development checkout (installed X.Y.Z, latest A.B.C). Update it yourself: run `git pull` in that checkout, then `./install.sh` from it.
  >
  > Changelog: https://github.com/ojCezarFerreira/grimoire/blob/main/CHANGELOG.md

**[Phase 6: Show changelog & authorize]**
- Fetch `https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/CHANGELOG.md` the same way as Phase 3.
- Extract every `## [VERSION] — DATE` section strictly between the installed version (exclusive) and the latest version (inclusive), with their `### Added` / `### Changed` / `### Fixed` / `### Removed` bullets verbatim. If the installed version is older than every section in the file, include all sections.
- Present the slice per `§ IDE-aware review`:
  - **IDE detected:** create `.grimoire/bag/drafts/` if needed and write `.grimoire/bag/drafts/grimoire-update-changelog-<epoch>.md` (`<epoch>` = `$(date +%s)` at write time; memorize the full path for cleanup). Tell the user in one short `📄` line that the changelog is open in the editor.
  - **Terminal-only fallback:** print the slice inline — concise, no commentary on top.
- If the changelog cannot be fetched, print `Changelog not available — proceeding without it.` and continue.
- PAUSE per `§ Pause-point pattern` (`grimoire-update`: changelog review): `Proceed with the update from X.Y.Z to A.B.C? (yes/no)`. Anything other than an unambiguous yes deletes the memorized draft (if any) and ends the skill cordially.

**[Phase 7: Run the installer]**
- Run through the shell (the same command on both harnesses):

  ```
  sh "${GRIMOIRE_HOME}/install.sh" --ref vA.B.C
  ```

  `A.B.C` is the latest version from Phase 3. The installer fetches and checks out that tag in the home, re-executes its freshly checked-out self, re-copies every `grimoire-*` skill for the detected agents, refreshes the dependencies, and keeps the global `config.toml`.
- Show the installer's closing summary to the user verbatim (version, home, agents, skills, deps, config, any `action:` line).
- If it exits non-zero, show its error output and stop: tell the user the update did not complete and that re-running `/grimoire-update` (or the `curl … | sh` one-liner) retries it.

**[Phase 8: Summary & cleanup]**
- Print: `Grimoire updated from X.Y.Z to A.B.C. Start a new session so the updated skills are loaded.`
- Point at the full changelog: `Full changelog: https://github.com/ojCezarFerreira/grimoire/blob/main/CHANGELOG.md`.
- Delete the memorized `.grimoire/bag/drafts/grimoire-update-changelog-<epoch>.md`, if Phase 6 wrote it — on success and on failure alike.

**[Notes]**
- This skill never spawns sub-agents and never makes commits in the consumer project. Every write to `${GRIMOIRE_HOME}` and to the installed skill directories belongs to `install.sh`; the skill only runs it.
- Operator-facing prose follows `§ User-facing language`; commands, paths, and version strings stay verbatim.
