# Architecture

## Stack

- **Markdown prompt files.** There is no application code, no build step and no runtime of its own. Each skill is a Markdown file with YAML frontmatter that Claude Code or Codex loads as instructions.
- **POSIX shell installer.** `install.sh` is plain `sh` (it runs under dash, bash, macOS `sh` and Git Bash on Windows). `install.ps1` is a thin PowerShell wrapper that locates Git for Windows' `bash.exe` and runs `install.sh` through it.
- **Third-party dependencies** are installed from their upstream sources at install time and never vendored: helper skills through `npx skills add`, the `agent-browser` CLI through `npm install -g`. The list lives in `deps.txt`.
- **GitHub Actions** (`.github/workflows/release.yml`) publishes releases.

## Repository layout

```
skills/grimoire-*/SKILL.md     one directory per skill (13): frontmatter + prompt body
AGENTES-CHAT.md                managed catalog/connector adapter and native construct protocol
GRIMOIRE-CONVENTIONS.md        shared rules, organised in "§" sections, read by every skill
install.sh                     installer (POSIX sh): clone/update, copy skills, deps, config
install.ps1                    Windows entry point, delegates to install.sh via Git Bash
deps.txt                       third-party dependency manifest read by install.sh
config.example.toml            template copied to the global config.toml on first install
VERSION                        the released version (one line)
CHANGELOG.md                   release notes, one section per version
scripts/test-install.sh        sandboxed installer test suite
.github/workflows/release.yml  tag + GitHub Release when VERSION changes on main
docs/                          this documentation
.grimoire/                     the repository's own Grimoire context (PROJECT.md, config.toml)
assets/                        README images
README.md, README.pt-BR.md     user documentation (English, Brazilian Portuguese)
CLAUDE.md                      maintainer notes for agents editing this repository
```

## Key modules

- **Skills.** Each `SKILL.md` opens with a `[Required Reading]` block naming the sections of `GRIMOIRE-CONVENTIONS.md` it depends on, followed by numbered phases. Skill bodies reference those sections instead of repeating them.
- **Conventions.** `GRIMOIRE-CONVENTIONS.md` is the single source of truth for every rule shared by more than one skill: the configuration schema, where workflow state is stored (GitHub issues, milestones and pull requests, or git-ignored local files), the automated review procedure, commit rules, pause points, and the differences between Claude Code and Codex.
- **Managed adapter.** `AGENTES-CHAT.md` maps the workspace catalog and connector operations, and specifies independent native construct storage: a Drive index plus board reference seeds, linked to existing GitHub/local pages. All 13 skills bootstrap this adapter before interpreting CLI examples on agentes.chat.
- **Installer.** `install.sh` resolves a home directory (default `~/.grimoire`, a git clone marked with `git config grimoire.managed true`), copies `skills/grimoire-*` into `~/.claude/skills/` and `~/.agents/skills/`, replaces the literal token `${GRIMOIRE_HOME}` in every copied `*.md` with the absolute home path, installs the entries of `deps.txt`, and creates `config.toml` in the home from `config.example.toml` when it is absent. Run from a checkout, it uses that checkout as the home (development mode) and clones nothing.
