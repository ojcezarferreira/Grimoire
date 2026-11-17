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

# --- a foreign grimoire-* folder survives; a stale shipped one is replaced ---
T=$(new_home foreign-skill)
mkdir -p "$T/.claude/skills/grimoire-foo" "$T/.claude/skills/grimoire-spec"
printf -- '---\nname: grimoire-foo\n---\nmine\n' >"$T/.claude/skills/grimoire-foo/SKILL.md"
printf -- '---\nname: grimoire-spec\n---\nold\n' >"$T/.claude/skills/grimoire-spec/SKILL.md"
printf 'stale\n' >"$T/.claude/skills/grimoire-spec/stale.txt"
with_home "$T" sh ./install.sh --no-deps --agent claude
check "foreign grimoire-foo: install exits 0" test $? -eq 0
check "foreign grimoire-foo: left in place" grep -q '^mine$' "$T/.claude/skills/grimoire-foo/SKILL.md"
check "foreign grimoire-foo: warned about" grep -q "warning: .*grimoire-foo is not a Grimoire skill" "$LOG"
check "foreign grimoire-foo: shipped skills installed alongside it" \
	test "$(count_skills "$T/.claude/skills")" -eq $((EXPECTED + 1))
check "stale shipped skill folder is replaced" test ! -e "$T/.claude/skills/grimoire-spec/stale.txt"

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
check "remote: fresh clone re-executes the cloned installer once" \
	test "$(grep -c "^re-executing installer from " "$LOG")" -eq 1

first=$(contents "$T/.claude")
with_home "$T" sh "$T/.grimoire/install.sh" --no-deps --ref "$ref"
check "remote: the clone's own install.sh updates in place (exit 0)" test $? -eq 0
check "remote: ...in remote mode, not dev mode" grep -q "^Updating " "$LOG"
check "remote: update run is idempotent" test "$(contents "$T/.claude")" = "$first"
check "remote: unchanged ref does not re-execute" \
	test "$(grep -c "^re-executing installer from " "$LOG")" -eq 0

# a throwaway branch one commit ahead, local to the sandbox clone
git -C "$T/.grimoire" checkout -q -b sandbox-next &&
	git -C "$T/.grimoire" -c user.name=test -c user.email=test@example.invalid \
		commit -q --allow-empty -m "sandbox: next release" &&
	git -C "$T/.grimoire" checkout -q "$ref"
with_home "$T" sh "$T/.grimoire/install.sh" --no-deps --ref sandbox-next
check "remote: update to another ref exits 0" test $? -eq 0
check "remote: changed ref re-executes the new installer exactly once" \
	test "$(grep -c "^re-executing installer from " "$LOG")" -eq 1
check "remote: clone now at the new ref" \
	test "$(git -C "$T/.grimoire" rev-parse HEAD)" = "$(git -C "$T/.grimoire" rev-parse sandbox-next)"

with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --uninstall --purge <install.sh
check "remote --uninstall --purge exits 0" test $? -eq 0
check "remote --uninstall empties both skill dirs" \
	test "$(count_skills "$T/.claude/skills")" -eq 0 -a "$(count_skills "$T/.agents/skills")" -eq 0
check "remote --purge deletes the home" test ! -e "$T/.grimoire"

# --- the documented self-deleting uninstall: the home's own install.sh -------
T=$(new_home self-purge)
with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --no-deps --ref "$ref" <install.sh
check "self-purge: managed clone installed (exit 0)" test $? -eq 0
with_home "$T" sh "$T/.grimoire/install.sh" --uninstall --purge
check "self-purge: sh ~/.grimoire/install.sh --uninstall --purge exits 0" test $? -eq 0
check "self-purge: the home is gone" test ! -e "$T/.grimoire"
check "self-purge: skills removed from both dirs" \
	test "$(count_skills "$T/.claude/skills")" -eq 0 -a "$(count_skills "$T/.agents/skills")" -eq 0

# --- --purge only deletes a managed clone ------------------------------------
# (a throwaway clone stands in for a dev checkout: the real one is never at risk)
git clone -q "$REPO" "$ROOT/dev checkout"
mkdir -p "$ROOT/plain dir" && printf 'keep me\n' >"$ROOT/plain dir/file.txt"
T=$(new_home purge)
for target in "$ROOT/dev checkout" "$ROOT/plain dir"; do
	with_home "$T" sh -s -- --uninstall --purge --home "$target" <install.sh
	check "--purge --home <$(basename "$target")> exits 0" test $? -eq 0
	check "--purge --home <$(basename "$target")> leaves it in place" \
		test -e "$target/.git" -o -f "$target/file.txt"
	check "--purge --home <$(basename "$target")> says why" \
		grep -q "not an installer-managed clone; not deleting" "$LOG"
done

# --- remote mode refuses a git checkout it did not clone ---------------------
USERREPO="$ROOT/user repo"
git init -q "$USERREPO" &&
	printf 'mine\n' >"$USERREPO/notes.txt" &&
	git -C "$USERREPO" -c core.autocrlf=false add notes.txt &&
	git -C "$USERREPO" -c user.name=test -c user.email=test@example.invalid commit -q -m mine
head_before=$(git -C "$USERREPO" rev-parse HEAD)
T=$(new_home foreign)
with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --no-deps --ref "$ref" --home "$USERREPO" <install.sh
check "remote --home <unmanaged git repo> fails" test $? -ne 0
check "...with the not-managed message" grep -q "is a git checkout not managed by the installer" "$LOG"
check "...leaving its HEAD untouched" test "$(git -C "$USERREPO" rev-parse HEAD)" = "$head_before"
check "...and unmarked" test -z "$(git -C "$USERREPO" config --local --get grimoire.managed)"
check "...and installs nothing" test ! -e "$T/.claude/skills"

# --- a managed clone at a custom home updates itself, not ~/.grimoire -------
T=$(new_home custom)
with_home "$T" env GRIMOIRE_REPO="$REPO" sh -s -- --no-deps --ref "$ref" --home "$T/custom" <install.sh
check "remote --home <custom> exits 0" test $? -eq 0
with_home "$T" sh "$T/custom/install.sh" --no-deps --ref "$ref"
check "custom clone's own install.sh exits 0" test $? -eq 0
check "...and does not create ~/.grimoire" test ! -e "$T/.grimoire"
check "...and keeps the custom clone as the home" grep -q "^home: .*/custom (clone at " "$LOG"
check_path "custom: skills point at the custom clone" "$T/custom/skills" "$T/.claude/skills" "$T/custom"

# --- deps: stub node/npx/npm/agent-browser log argv and drain stdin --------
STUB="$ROOT/stub bin"
LATER="$ROOT/stub later"
STUBLOG="$ROOT/stub.log"
mkdir -p "$STUB" "$LATER"
write_stub() { # <dir> <name> [extra shell line]
	cat >"$1/$2" <<EOF
#!/bin/sh
printf '%s\n' "$2 \$*" >>"$STUBLOG"
cat >>"$STUBLOG.stdin"
${3:-}
EOF
	chmod +x "$1/$2"
}
write_stub "$STUB" node
write_stub "$STUB" npx
write_stub "$LATER" agent-browser
# npm "installs" agent-browser by putting its stub on PATH
write_stub "$STUB" npm "[ \"\$*\" = 'install -g agent-browser' ] && cp \"$LATER/agent-browser\" \"$STUB/\""
: >"$STUBLOG"
: >"$STUBLOG.stdin"
GITDIR=$(dirname "$(command -v git)")
T=$(new_home deps)
with_home "$T" env PATH="$STUB:$GITDIR:/usr/bin:/bin" sh ./install.sh
check "install with deps (stubbed) exits 0" test $? -eq 0
expected=""
copy=""
[ "$windows" -eq 1 ] && copy=" --copy"
lines=0
while read -r type source name post; do
	case $type in '' | '#'*) continue ;; esac
	lines=$((lines + 1))
	case $type in
	skill)
		expected+="npx -y skills add $source --skill $name -g -y -a claude-code$copy"$'\n'
		expected+="npx -y skills add $source --skill $name -g -y -a codex$copy"$'\n'
		;;
	npm)
		expected+="npm install -g $source"$'\n'
		[ -n "$post" ] && expected+="$post"$'\n'
		;;
	esac
done <deps.txt
check "deps: exact dependency commands, in deps.txt order" test "$(cat "$STUBLOG")"$'\n' = "$expected"
check "deps: no dependency command saw deps.txt on stdin" test ! -s "$STUBLOG.stdin"
skill_lines=$(grep -c '^skill ' deps.txt)
check "deps: all $lines deps.txt lines processed (summary ✓ count)" \
	test "$(grep -c '^  ✓ ' "$LOG")" -eq $((skill_lines * 2 + lines - skill_lines))

# --- warning when the 0.13 plugin is still installed -----------------------
T=$(new_home plugin)
mkdir -p "$T/.claude/plugins"
printf '{"version":2,"plugins":{"grimoire@grimoire":[{"scope":"user"}]}}\n' \
	>"$T/.claude/plugins/installed_plugins.json"
with_home "$T" sh ./install.sh --no-deps --agent claude
check "plugin fixture: install exits 0" test $? -eq 0
check "plugin fixture: warns to run claude plugin uninstall grimoire@grimoire" \
	grep -q "warning: .*claude plugin uninstall grimoire@grimoire" "$LOG"

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
