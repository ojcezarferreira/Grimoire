# Development

## Requirements

- `git`, a POSIX `sh` (Git Bash on Windows), and `bash` for the test suite.
- Node.js with `npx` / `npm` only to install the third-party dependencies (skip them with `--no-deps`).
- Python 3.11+ for the offline distribution/prompt contract checks (standard library only).

## Install from a checkout

```sh
./install.sh --no-deps        # development mode: this checkout is the home, nothing is cloned
./install.sh --dry-run        # print every action, write nothing
```

Re-run `./install.sh` after editing a skill: the agents read the installed copies under `~/.claude/skills/` and `~/.agents/skills/`, not the checkout. Development mode writes the git-ignored global `config.toml` into the checkout root. On Windows, `.\install.ps1 -- --no-deps` does the same through Git Bash.

## Test

```sh
bash scripts/test-install.sh
```

Runs the installer against throwaway `HOME` directories — no network, the real home is never touched. It covers development mode, `--agent`, token substitution in paths with spaces, remote mode (offline, cloning this checkout's committed `HEAD`), updates, `--uninstall`, and `--purge`. Remote-mode checks see only committed changes.

## Managed-workspace contracts

```sh
python3 scripts/test-contracts.py
```

Checks skill frontmatter, release-pinned bootstrap consistency, referenced convention sections, native dispatch in every construct consumer, config defaults and local Markdown links. These are distribution/prompt contract checks; they do not execute an LLM or prove a bot followed the protocol. The [acceptance matrix](agentes-chat-validation.md) describes behavioral checks against actual platform tools before rollout.

Managed skill updates use the catalog tools described in `AGENTES-CHAT.md`; do not refresh CLI skill folders when maintaining a workspace catalog.

## Lint

```sh
sh -n install.sh
```

There is no build step.

## Release

1. In one commit, bump `VERSION` and add the `## [X.Y.Z] — YYYY-MM-DD` section at the top of `CHANGELOG.md`, with its link reference at the bottom.
2. Merge to `main`. The release workflow, triggered by the change to `VERSION`, creates the tag `vX.Y.Z`, extracts that version's `CHANGELOG.md` section, and publishes the GitHub Release; it fails when the section is missing.
3. Installations pick the release up through `/grimoire-update` or by re-running the installer, which installs the latest `v*` tag by default.
