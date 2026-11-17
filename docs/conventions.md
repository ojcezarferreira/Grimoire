# Conventions

## Content

- Rules shared by more than one skill are written once, in `GRIMOIRE-CONVENTIONS.md`. Skill bodies point at the relevant `§` section and never restate the rule; when a rule changes, only that file changes.
- Adding or removing a `§` section in `GRIMOIRE-CONVENTIONS.md` means updating the `[Required Reading]` block of every skill that depends on it.
- Strings shown to the operator are written in English inside the skills (they are translated at run time); commit messages, file contents and identifiers are always English.
- `README.md` (English) and `README.pt-BR.md` (Brazilian Portuguese) are kept in sync. Every other file is English.

## Skill files

- The frontmatter keys `name`, `description` and `argument-hint` are load-bearing: `name` equals the skill's directory name, `description` stays within 1024 characters, and the `---` delimiters stay in place.
- `$ARGUMENTS` and `$1` are invocation substitutions and are kept verbatim.
- Paths to files shipped with Grimoire are written with the literal token `${GRIMOIRE_HOME}`, which the installer replaces with the absolute install path. Never hardcode a path.

## Shell

- `install.sh` stays POSIX `sh`: no bashisms, no `sed -i`, every path quoted (home directories may contain spaces).
- Shell scripts are checked out with LF line endings (`.gitattributes`).

## Commits and releases

- Conventional Commits in English (`feat:`, `fix:`, `docs:`, `chore:`, …), one logical change per commit.
- `VERSION` is the single source of the release number. A release is one commit that bumps `VERSION` and adds the matching `## [X.Y.Z] — YYYY-MM-DD` section to `CHANGELOG.md`.
