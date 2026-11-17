# Overview

## Purpose

Grimoire is a set of agent skills for **Claude Code** and **Codex** that impose a disciplined workflow on AI-assisted software work: a request is first turned into an agreed specification through an interview with the developer, then into an executable plan, then into code written test-first on an isolated branch, reviewed automatically, and delivered as a pull request that waits for human review.

The repository ships three things:

- the skills themselves (`skills/grimoire-*/SKILL.md`, one Markdown prompt file each);
- `GRIMOIRE-CONVENTIONS.md`, the shared rulebook every skill reads at run time;
- an installer (`install.sh`, `install.ps1`) that copies the skills into the agents' skill directories and installs the third-party helper skills and CLI they rely on.

## Audience

Developers who use Claude Code or Codex and can read code, evaluate a plan, and own the decisions a workflow surfaces. It is not aimed at non-technical users.

## Stage

Early, active development. The skills are used day to day by the author but have not been exercised across many projects or teams. Breaking changes between minor versions are expected; `CHANGELOG.md` records each one.

See the [README](../README.md) for the user-facing description and [GRIMOIRE-CONVENTIONS.md](../GRIMOIRE-CONVENTIONS.md) for the rules the skills follow.
