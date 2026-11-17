# Grimoire — Grimoire index

## Documentation
- docs/overview.md — what Grimoire is, who it is for, and its stage.
- docs/architecture.md — markdown skills, conventions file and POSIX installer; repository layout.
- docs/conventions.md — content, skill-file, shell and commit rules for this repository.
- docs/development.md — install from a checkout, installer tests, lint, and the release process.

## Grimoire rules
- `GRIMOIRE-CONVENTIONS.md` is the single source of truth; skill bodies reference its `§` sections and never restate rules.
- Run `bash scripts/test-install.sh` before committing installer changes (`install.sh`, `install.ps1`, `deps.txt`, `config.example.toml`).
- A release is one commit bumping `VERSION` plus its `CHANGELOG.md` entry.
- Never commit `.superpowers/`.
