#!/usr/bin/env bash
# Sandbox-HOME test of install.sh and install.ps1: no network, never touches the
# real home. Every run gets a throwaway HOME with .claude/ and .codex/ in it.
#
#   bash scripts/test-install.sh
#
# Remote mode is exercised offline: the script is fed through stdin with
# GRIMOIRE_REPO pointing at this checkout, so it clones the committed HEAD.
set -u
unset GRIMOIRE_HOME GRIMOIRE_REPO

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$REPO" || exit 1
# shellcheck disable=SC2016 # the literal token
TOKEN='${GRIMOIRE_HOME}'
ROOT=$(mktemp -d)
LOG="$ROOT/install.log"
had_config=0
[ -f "$REPO/config.toml" ] && had_config=1

cleanup() {
	rm -rf "$ROOT"
	# dev-mode runs write the git-ignored global config into the checkout
	[ "$had_config" -eq 1 ] || rm -f "$REPO/config.toml"
}
trap cleanup EXIT

failures=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() {
	printf 'FAIL  %s\n' "$1"
	failures=$((failures + 1))
	[ -s "$LOG" ] && sed 's/^/      | /' "$LOG" | tail -n 15
}
check() {
	local desc=$1
	shift
	if "$@"; then pass "$desc"; else fail "$desc"; fi
}

windows=0
case $(uname -s) in MINGW* | MSYS* | CYGWIN*) windows=1 ;; esac
native() { if [ "$windows" -eq 1 ]; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

new_home() {
	mkdir -p "$ROOT/$1/.claude" "$ROOT/$1/.codex"
	printf '%s\n' "$ROOT/$1"
}

# with_home <home> <command...>: runs the command with that HOME, output in $LOG.
with_home() {
	local h=$1
	shift
	if command -v cygpath >/dev/null 2>&1; then
		HOME="$h" USERPROFILE="$(cygpath -w "$h")" "$@" >"$LOG" 2>&1
	else
		HOME="$h" "$@" >"$LOG" 2>&1
	fi
}

snapshot() { (cd "$1" && find . -print | LC_ALL=C sort); }
contents() { (cd "$1" && find . -type f -exec cksum {} + | LC_ALL=C sort); }
count_skills() { find "$1" -mindepth 1 -maxdepth 1 -type d -name 'grimoire-*' 2>/dev/null | wc -l; }
EXPECTED=$(count_skills "$REPO/skills")

has_all_skills() { # <skills dir>
	local d
	[ "$(count_skills "$1")" -eq "$EXPECTED" ] || return 1
	for d in "$REPO"/skills/grimoire-*/; do
		[ -f "$1/$(basename "$d")/SKILL.md" ] || return 1
	done
}
no_token_left() { ! grep -rqF --include='*.md' "$TOKEN" "$@"; }
is_absolute() { case $1 in /* | [A-Za-z]:/*) return 0 ;; *) return 1 ;; esac; }

# check_path <label> <source skills dir> <installed skills dir> <home (POSIX)>
# Every installed copy of a source *.md holding the token now holds <home>/.
check_path() {
	local label=$1 src=$2 dest=$3 home=$4 value files f ok=0
	value=$(native "$home")
	files=$(cd "$src" && grep -rlF --include='*.md' "$TOKEN" .)
	if [ -z "$files" ]; then
		printf 'SKIP  %s (no %s in these skills yet; the fixture asserts cover it)\n' "$label" "$TOKEN"
		return
	fi
	is_absolute "$value" && [ -f "$home/GRIMOIRE-CONVENTIONS.md" ] || ok=1
	while IFS= read -r f; do
		grep -qF "$value/" "$dest/$f" 2>/dev/null || ok=1
	done <<<"$files"
	check "$label ($value)" test "$ok" -eq 0
}

printf 'Installer tests: %s skills in %s\n' "$EXPECTED" "$REPO"
sh -n install.sh
check "install.sh parses (sh -n)" test $? -eq 0
if command -v dash >/dev/null 2>&1; then
	dash -n install.sh
	check "install.sh parses (dash -n)" test $? -eq 0
fi

# --- dev mode: sh ./install.sh from this checkout ---------------------------
T=$(new_home dev)
before=$(snapshot "$T")
with_home "$T" sh ./install.sh --dry-run --no-deps
check "dev --dry-run --no-deps exits 0" test $? -eq 0
check "dev --dry-run writes nothing under HOME" test "$(snapshot "$T")" = "$before"
check "dev --dry-run writes no config.toml into the checkout" \
	test "$had_config" -eq 1 -o ! -e "$REPO/config.toml"

with_home "$T" sh ./install.sh --no-deps
check "dev --no-deps exits 0" test $? -eq 0
check "dev: $EXPECTED skills under .claude/skills" has_all_skills "$T/.claude/skills"
check "dev: $EXPECTED skills under .agents/skills" has_all_skills "$T/.agents/skills"
check "dev: no $TOKEN left in installed *.md" no_token_left "$T/.claude/skills" "$T/.agents/skills"
check_path "dev: .claude skills point at the checkout" "$REPO/skills" "$T/.claude/skills" "$REPO"
check_path "dev: .agents skills point at the checkout" "$REPO/skills" "$T/.agents/skills" "$REPO"
check "dev: global config.toml exists in the checkout" test -f "$REPO/config.toml"

first=$(contents "$T")
with_home "$T" sh ./install.sh --no-deps
check "dev: second run exits 0" test $? -eq 0
check "dev: second run is idempotent (same files, same content)" test "$(contents "$T")" = "$first"

with_home "$T" sh ./install.sh --uninstall
check "dev --uninstall exits 0" test $? -eq 0
check "dev --uninstall empties .claude/skills" test "$(count_skills "$T/.claude/skills")" -eq 0
check "dev --uninstall empties .agents/skills" test "$(count_skills "$T/.agents/skills")" -eq 0

T=$(new_home codex-only)
with_home "$T" sh ./install.sh --agent codex --no-deps
check "--agent codex exits 0" test $? -eq 0
check "--agent codex installs into .agents/skills" has_all_skills "$T/.agents/skills"
check "--agent codex leaves .claude untouched" test ! -e "$T/.claude/skills"

# --- fixture: token substitution in a path with a space and '&' ------------
FIX="$ROOT/src dir & co"
mkdir -p "$FIX"
cp -R install.sh GRIMOIRE-CONVENTIONS.md VERSION config.example.toml deps.txt skills "$FIX/"
printf '\nSee %s/GRIMOIRE-CONVENTIONS.md and %s/VERSION.\n' "$TOKEN" "$TOKEN" \
	>>"$FIX/skills/grimoire-init/SKILL.md"
mkdir -p "$FIX/skills/grimoire-init/references"
printf 'Nested: %s/install.sh\n' "$TOKEN" >"$FIX/skills/grimoire-init/references/nested.md"
shell=sh
command -v dash >/dev/null 2>&1 && shell=dash
T=$(new_home fixture)
with_home "$T" "$shell" "$FIX/install.sh" --no-deps --agent claude
check "fixture ($shell) exits 0" test $? -eq 0
FIXP=$(cd "$FIX" && pwd -P)
check "fixture: no $TOKEN left in installed *.md" no_token_left "$T/.claude/skills"
check_path "fixture: SKILL.md and nested *.md hold the absolute home" \
	"$FIX/skills" "$T/.claude/skills" "$FIXP"
with_home "$T" "$shell" "$FIX/install.sh" --uninstall --purge
check "fixture --uninstall --purge exits 0" test $? -eq 0
check "fixture --purge never deletes a dev checkout" test -f "$FIX/GRIMOIRE-CONVENTIONS.md"

# --- remote mode, offline: sh -s < install.sh, cloning this checkout ------
ref=$(git rev-parse --abbrev-ref HEAD)
[ "$ref" = HEAD ] && ref=$(git rev-parse HEAD)
T=$(new_home remote)
with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --no-deps --ref "$ref" <install.sh
check "remote (stdin) --ref $ref exits 0" test $? -eq 0
check "remote: clone has GRIMOIRE-CONVENTIONS.md" test -f "$T/.grimoire/GRIMOIRE-CONVENTIONS.md"
check "remote: clone is marked grimoire.managed" \
	test "$(git -C "$T/.grimoire" config --local --get grimoire.managed)" = true
check "remote: $EXPECTED skills under .claude/skills" has_all_skills "$T/.claude/skills"
check "remote: $EXPECTED skills under .agents/skills" has_all_skills "$T/.agents/skills"
check "remote: no $TOKEN left in installed *.md" no_token_left "$T/.claude/skills" "$T/.agents/skills"
check_path "remote: skills point at the clone" "$T/.grimoire/skills" "$T/.claude/skills" "$T/.grimoire"
check "remote: global config.toml created in the clone" test -f "$T/.grimoire/config.toml"

first=$(contents "$T/.claude")
with_home "$T" sh "$T/.grimoire/install.sh" --no-deps --ref "$ref"
check "remote: the clone's own install.sh updates in place (exit 0)" test $? -eq 0
check "remote: ...in remote mode, not dev mode" grep -q "^Updating " "$LOG"
check "remote: update run is idempotent" test "$(contents "$T/.claude")" = "$first"

with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --uninstall --purge <install.sh
check "remote --uninstall --purge exits 0" test $? -eq 0
check "remote --uninstall empties both skill dirs" \
	test "$(count_skills "$T/.claude/skills")" -eq 0 -a "$(count_skills "$T/.agents/skills")" -eq 0
check "remote --purge deletes the home" test ! -e "$T/.grimoire"

# --- install.ps1 ---------------------------------------------------------------
if command -v powershell >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
	T=$(new_home ps1)
	before=$(snapshot "$T")
	with_home "$T" powershell -NoProfile -ExecutionPolicy Bypass \
		-File "$(cygpath -w "$REPO/install.ps1")" -- --dry-run --no-deps
	check "install.ps1 -- --dry-run --no-deps exits 0" test $? -eq 0
	check "install.ps1 reached install.sh's dry run" grep -q "^Dry run: nothing was written" "$LOG"
	# the PowerShell host itself creates AppData/ under the redirected USERPROFILE
	check "install.ps1 dry run writes nothing under HOME" 		test "$(snapshot "$T" | grep -v "^./AppData")" = "$before"
else
	printf 'SKIP  install.ps1 (powershell not available)\n'
fi

LOG=""
if [ "$failures" -eq 0 ]; then
	printf '\nAll installer tests passed.\n'
else
	printf '\n%s installer test(s) failed.\n' "$failures"
	exit 1
fi
