#!/bin/sh
# Grimoire installer: copies the grimoire-* skills into Claude Code and Codex.
#
#   curl -fsSL https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/install.sh | sh -s -- [flags]
#   ./install.sh [flags]      # dev mode, from a checkout
#
# Flags:
#   --ref <tag|branch>     version to install (default: latest v* tag; "main" = edge)
#   --agent claude|codex   install for this agent only (repeatable; overrides detection)
#   --no-deps              skip the third-party dependencies listed in deps.txt
#   --dry-run              print every action, write nothing
#   --uninstall [--purge]  remove the grimoire-* skills; --purge also deletes the home
#   --home <dir>           Grimoire home (default: $GRIMOIRE_HOME, else $HOME/.grimoire)
#   -h, --help             show this help
#
# Environment:
#   GRIMOIRE_HOME   same as --home
#   GRIMOIRE_REPO   git URL cloned in remote mode
#                   (default https://github.com/ojCezarFerreira/grimoire.git)
#
# Dev mode: when this file sits in a Grimoire checkout (its directory holds
# GRIMOIRE-CONVENTIONS.md) that the installer did not clone itself, that checkout
# is both the source and the home: nothing is cloned or fetched, and --ref,
# --home and GRIMOIRE_HOME are ignored with a notice. A clone made by this
# installer is marked with `git config grimoire.managed true`, so running its
# own install.sh (what grimoire-update does) fetches and checks out --ref.

set -u

REPO_DEFAULT=https://github.com/ojCezarFerreira/grimoire.git
# shellcheck disable=SC2016 # the literal token, never expanded
TOKEN='${GRIMOIRE_HOME}'

opt_ref=""
opt_home=""
opt_no_deps=0
opt_dry_run=0
opt_uninstall=0
opt_purge=0
agent_forced=0
want_claude=0
want_codex=0

is_windows=0
dev_mode=0
home=""
agents=""
ref_used=""
skills_report=""
deps_report=""
config_report=""
plugin_found=0

log() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

# Runs a command, or only prints it under --dry-run.
run() {
	if [ "$opt_dry_run" -eq 1 ]; then
		log "[dry-run] $*"
		return 0
	fi
	"$@"
}

usage() {
	cat <<'EOF'
Usage: install.sh [--ref <tag|branch>] [--agent claude|codex]... [--no-deps]
                  [--dry-run] [--uninstall [--purge]] [--home <dir>]

  curl -fsSL https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/install.sh | sh -s -- [flags]

  --ref <tag|branch>     version to install (default: latest v* tag; "main" = edge)
  --agent claude|codex   install for this agent only (repeatable; overrides detection)
  --no-deps              skip the third-party dependencies listed in deps.txt
  --dry-run              print every action, write nothing
  --uninstall [--purge]  remove the grimoire-* skills; --purge also deletes the home
  --home <dir>           Grimoire home (default: $GRIMOIRE_HOME, else $HOME/.grimoire)
EOF
}

add_agent() {
	case $1 in
	claude) want_claude=1 ;;
	codex) want_codex=1 ;;
	*) die "unknown agent '$1' (expected claude or codex)" ;;
	esac
	agent_forced=1
}

parse_args() {
	while [ $# -gt 0 ]; do
		case $1 in
		--ref)
			[ $# -ge 2 ] || die "--ref needs a value"
			opt_ref=$2
			shift 2
			;;
		--ref=*) opt_ref=${1#--ref=} && shift ;;
		--agent)
			[ $# -ge 2 ] || die "--agent needs a value (claude or codex)"
			add_agent "$2"
			shift 2
			;;
		--agent=*) add_agent "${1#--agent=}" && shift ;;
		--home)
			[ $# -ge 2 ] || die "--home needs a directory"
			opt_home=$2
			shift 2
			;;
		--home=*) opt_home=${1#--home=} && shift ;;
		--no-deps) opt_no_deps=1 && shift ;;
		--dry-run) opt_dry_run=1 && shift ;;
		--uninstall) opt_uninstall=1 && shift ;;
		--purge) opt_purge=1 && shift ;;
		-h | --help) usage && exit 0 ;;
		*) die "unknown option '$1' (see --help)" ;;
		esac
	done
	if [ "$opt_purge" -eq 1 ] && [ "$opt_uninstall" -eq 0 ]; then
		die "--purge only works together with --uninstall"
	fi
}

detect_os() {
	case $(uname -s 2>/dev/null) in
	MINGW* | MSYS* | CYGWIN*) is_windows=1 ;;
	*) is_windows=0 ;;
	esac
}

# Absolute POSIX form of a path that may not exist yet.
abs_path() {
	if [ "$is_windows" -eq 1 ] && command -v cygpath >/dev/null 2>&1; then
		p=$(cygpath -ua "$1")
	else
		case $1 in
		/*) p=$1 ;;
		*) p="$PWD/$1" ;;
		esac
	fi
	[ "$p" = / ] || p=${p%/}
	printf '%s\n' "$p"
}

# The form written into the skills: C:/Users/... on Windows, the POSIX path elsewhere.
native_path() {
	if [ "$is_windows" -eq 1 ] && command -v cygpath >/dev/null 2>&1; then
		cygpath -m "$1"
	else
		printf '%s\n' "$1"
	fi
}

is_managed_clone() {
	command -v git >/dev/null 2>&1 &&
		[ "$(git -C "$1" config --local --get grimoire.managed 2>/dev/null)" = true ]
}

resolve_home() {
	requested=${opt_home:-${GRIMOIRE_HOME:-}}
	script_dir=""
	if [ -f "$0" ]; then
		script_dir=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P) || script_dir=""
	fi
	if [ -n "$script_dir" ] && [ -f "$script_dir/GRIMOIRE-CONVENTIONS.md" ] &&
		! is_managed_clone "$script_dir"; then
		dev_mode=1
		home=$script_dir
		if [ -n "$requested" ] && [ "$(abs_path "$requested")" != "$home" ]; then
			log "notice: dev mode, ignoring --home/GRIMOIRE_HOME ($requested); the home is this checkout"
		fi
		if [ -n "$opt_ref" ]; then
			log "notice: dev mode, ignoring --ref $opt_ref; update this checkout with git yourself"
		fi
	else
		home=$(abs_path "${requested:-$HOME/.grimoire}")
	fi
}

skills_dir() {
	case $1 in
	claude) printf '%s\n' "$HOME/.claude/skills" ;;
	codex) printf '%s\n' "$HOME/.agents/skills" ;;
	esac
}

agent_id() {
	case $1 in
	claude) printf '%s\n' claude-code ;;
	codex) printf '%s\n' codex ;;
	esac
}

detect_agents() {
	if [ "$agent_forced" -eq 0 ]; then
		if [ -d "$HOME/.claude" ] || command -v claude >/dev/null 2>&1; then want_claude=1; fi
		if [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then want_codex=1; fi
	fi
	agents=""
	[ "$want_claude" -eq 0 ] || agents="claude"
	[ "$want_codex" -eq 0 ] || agents="${agents:+$agents }codex"
	[ -n "$agents" ] || die "no supported agent found (no ~/.claude or ~/.codex, no claude or codex on PATH). Install Claude Code or Codex first, or pass --agent claude|codex"
}

preflight() {
	if [ "$dev_mode" -eq 0 ] && ! command -v git >/dev/null 2>&1; then
		die "git is required (https://git-scm.com/downloads)"
	fi
}

# Latest v* tag of a remote; empty output when it has none.
latest_tag() {
	out=$(git ls-remote --tags --refs --sort=-v:refname "$1" 'v*') || return 1
	printf '%s\n' "$out" | sed -n '1s|.*refs/tags/||p'
}

sync_home() {
	repo=${GRIMOIRE_REPO:-$REPO_DEFAULT}
	if [ -e "$home/.git" ] && [ -z "${GRIMOIRE_REPO:-}" ]; then
		repo=$(git -C "$home" remote get-url origin 2>/dev/null) || repo=$REPO_DEFAULT
	fi
	ref_used=$opt_ref
	if [ -z "$ref_used" ]; then
		ref_used=$(latest_tag "$repo") || die "cannot reach $repo to find the latest release (network?)"
		[ -n "$ref_used" ] || ref_used=main
	fi
	if [ -e "$home/.git" ]; then
		log "Updating $home to $ref_used"
		run git -C "$home" fetch -q --tags --force origin || die "git fetch failed in $home (network?)"
		if git -C "$home" rev-parse -q --verify "refs/remotes/origin/$ref_used" >/dev/null; then
			run git -C "$home" checkout -q -B "$ref_used" "origin/$ref_used" ||
				die "cannot check out $ref_used in $home (local changes?)"
		else
			run git -C "$home" checkout -q "$ref_used" ||
				die "cannot check out $ref_used in $home (unknown ref or local changes?)"
		fi
		run git -C "$home" config grimoire.managed true
	elif [ -e "$home" ] && [ -n "$(ls -A "$home" 2>/dev/null)" ]; then
		die "$home exists and is not a git clone; remove it or pass --home <dir>"
	else
		log "Cloning $repo ($ref_used) into $home"
		run git clone -q -c core.autocrlf=false -c grimoire.managed=true "$repo" "$home" ||
			die "git clone of $repo failed (network?)"
		# checkout rather than clone --branch: also accepts a commit id
		run git -C "$home" checkout -q "$ref_used" ||
			die "ref $ref_used not found in $repo"
	fi
}

# Replaces the literal ${GRIMOIRE_HOME} in every *.md under $1 with $2.
substitute_token() {
	if [ "$opt_dry_run" -eq 1 ]; then
		log "[dry-run] replace $TOKEN with $2 in $1/**/*.md"
		return 0
	fi
	repl=$(printf '%s\n' "$2" | sed 's/[\\&|]/\\&/g')
	find "$1" -type f -name '*.md' | while IFS= read -r f; do
		grep -qF "$TOKEN" "$f" || continue
		sed 's|[$][{]GRIMOIRE_HOME[}]|'"$repl"'|g' "$f" >"$f.tmp" && mv "$f.tmp" "$f" ||
			{
				rm -f "$f.tmp"
				exit 1
			}
	done || die "could not substitute $TOKEN in $1"
}

install_skills() {
	src="$home/skills"
	value=$(native_path "$home")
	if [ ! -d "$src" ] && [ "$opt_dry_run" -eq 0 ]; then
		die "no skills found in $src"
	fi
	for agent in $agents; do
		target=$(skills_dir "$agent")
		run mkdir -p "$target" || die "cannot create $target"
		for old in "$target"/grimoire-*; do
			[ -d "$old" ] || continue
			run rm -rf "$old" || die "cannot remove $old"
		done
		n=0
		for dir in "$src"/grimoire-*/; do
			[ -d "$dir" ] || continue
			name=$(basename "$dir")
			run cp -R "$src/$name" "$target/$name" || die "cannot copy $name to $target"
			substitute_token "$target/$name" "$value"
			n=$((n + 1))
		done
		[ -d "$src" ] || log "[dry-run] copy $src/grimoire-*/ to $target/"
		skills_report="$skills_report  $agent: $n skills -> $target/grimoire-*
"
	done
}

record_dep() { deps_report="$deps_report  $*
"; }

install_skill_dep() {
	dep_source=$1
	dep_name=$2
	for agent in $agents; do
		id=$(agent_id "$agent")
		set -- npx -y skills add "$dep_source" --skill "$dep_name" -g -y -a "$id"
		[ "$is_windows" -eq 0 ] || set -- "$@" --copy
		log "Installing skill $dep_name for $id"
		if run "$@"; then
			record_dep "✓ $dep_name ($id)"
		else
			warn "could not install skill $dep_name for $id; continuing without it"
			record_dep "! $dep_name ($id) failed"
		fi
	done
}

install_npm_dep() {
	if command -v "$2" >/dev/null 2>&1; then
		log "$2 already on PATH"
	elif ! command -v npm >/dev/null 2>&1; then
		warn "npm not found; skipping $1"
		record_dep "! $2 skipped (no npm)"
		return 0
	else
		log "Installing npm package $1"
		if ! run npm install -g "$1"; then
			warn "npm install -g $1 failed; continuing without it"
			record_dep "! $2 failed"
			return 0
		fi
	fi
	if [ -n "$3" ]; then
		log "Running $3"
		if ! run sh -c "$3"; then
			warn "'$3' failed; continuing"
			record_dep "! $2 ($3 failed)"
			return 0
		fi
	fi
	record_dep "✓ $2"
}

install_deps() {
	if [ "$opt_no_deps" -eq 1 ]; then
		record_dep "skipped (--no-deps)"
		return 0
	fi
	manifest="$home/deps.txt"
	if [ ! -f "$manifest" ]; then
		[ "$opt_dry_run" -eq 1 ] || warn "$manifest not found; skipping dependencies"
		record_dep "skipped (no deps.txt)"
		return 0
	fi
	if ! command -v node >/dev/null 2>&1 || ! command -v npx >/dev/null 2>&1; then
		warn "node/npx not found; skipping dependencies (reviews run without browser/lens checks). Install Node.js and re-run"
		record_dep "skipped (node/npx not found)"
		return 0
	fi
	while read -r type source name post || [ -n "${type:-}" ]; do
		case $type in '' | '#'*) continue ;; esac
		case $type in
		skill) install_skill_dep "$source" "$name" ;;
		npm) install_npm_dep "$source" "$name" "$post" ;;
		*)
			warn "deps.txt: unknown type '$type' for $name; skipped"
			record_dep "! $name skipped (unknown type $type)"
			;;
		esac
	done <"$manifest"
}

install_config() {
	config="$home/config.toml"
	if [ -f "$config" ]; then
		config_report="$config (kept)"
		return 0
	fi
	run cp "$home/config.example.toml" "$config" || die "cannot create $config"
	config_report="$config (created from config.example.toml)"
}

check_plugin() {
	f="$HOME/.claude/plugins/installed_plugins.json"
	if [ -f "$f" ] && grep -q 'grimoire@grimoire' "$f"; then
		plugin_found=1
		warn "the Grimoire Claude Code plugin is still installed; run 'claude plugin uninstall grimoire@grimoire' to avoid duplicate skills"
	fi
}

uninstall() {
	if [ "$agent_forced" -eq 1 ]; then
		detect_agents
	else
		agents="claude codex"
	fi
	for agent in $agents; do
		target=$(skills_dir "$agent")
		n=0
		for d in "$target"/grimoire-*; do
			[ -d "$d" ] || continue
			run rm -rf "$d" || die "cannot remove $d"
			n=$((n + 1))
		done
		log "Removed $n Grimoire skills from $target"
	done
	manifest="$home/deps.txt"
	log "Dependencies were left in place. To remove them:"
	if [ -f "$manifest" ]; then
		while read -r type source name post || [ -n "${type:-}" ]; do
			case $type in
			skill) log "  npx skills remove $name -g" ;;
			npm) log "  npm uninstall -g $source" ;;
			esac
		done <"$manifest"
	else
		log "  see deps.txt in https://github.com/ojCezarFerreira/grimoire"
	fi
	if [ "$opt_purge" -eq 1 ]; then
		if [ "$dev_mode" -eq 1 ]; then
			log "--purge: $home is a dev checkout; not deleting it"
		elif [ -e "$home" ]; then
			run rm -rf "$home" || die "cannot delete $home"
			log "Deleted $home"
		fi
	fi
}

print_summary() {
	version=""
	[ ! -f "$home/VERSION" ] || version=$(tr -d '[:space:]' <"$home/VERSION")
	if [ "$dev_mode" -eq 1 ]; then
		kind="dev checkout"
	else
		kind="clone at $ref_used"
	fi
	log ""
	[ "$opt_dry_run" -eq 0 ] || log "Dry run: nothing was written."
	log "Grimoire ${version:-(version unknown)}"
	log "home:    $home ($kind)"
	log "agents:  $agents"
	log "skills:"
	printf '%s' "$skills_report"
	log "deps:"
	printf '%s' "$deps_report"
	log "config:  $config_report"
	if [ "$plugin_found" -eq 1 ]; then
		log "action:  run 'claude plugin uninstall grimoire@grimoire' (the old plugin duplicates these skills)"
	fi
	log "next:    start a new session; run /grimoire-init in a project"
}

main() {
	parse_args "$@"
	detect_os
	resolve_home
	if [ "$opt_uninstall" -eq 1 ]; then
		uninstall
		return 0
	fi
	preflight
	detect_agents
	[ "$dev_mode" -eq 1 ] || sync_home
	install_skills
	install_deps
	install_config
	check_plugin
	print_summary
}

# One line on purpose: the shell has parsed it whole before main can rewrite this
# file (a git checkout of the home during an update).
main "$@" </dev/null; exit $?
