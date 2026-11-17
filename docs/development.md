# Development

## Requirements

- `git`, a POSIX `sh` (Git Bash on Windows), and `bash` for the test suite.
- Node.js with `npx` / `npm` only to install the third-party dependencies (skip them with `--no-deps`).

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

## Lint

```sh
sh -n install.sh
```

There is no build step.

## Release

1. In one commit, bump `VERSION` and add the `## [X.Y.Z] — YYYY-MM-DD` section at the top of `CHANGELOG.md`, with its link reference at the bottom.
2. Merge to `main`. The release workflow, triggered by the change to `VERSION`, creates the tag `vX.Y.Z`, extracts that version's `CHANGELOG.md` section, and publishes the GitHub Release; it fails when the section is missing.
3. Installations pick the release up through `/grimoire-update` or by re-running the installer, which installs the latest `v*` tag by default.
