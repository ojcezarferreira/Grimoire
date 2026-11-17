# Grimoire installer for Windows: runs install.sh through Git for Windows' bash.
#   irm https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/install.ps1 | iex
#   .\install.ps1 -- --no-deps --agent codex      (from a checkout; flags as in install.sh)
# No param() block on purpose: PowerShell 5.1 would bind --flags as its own parameters;
# the automatic $args keeps them verbatim (a leading -- is dropped).
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { throw 'Grimoire needs Git for Windows (https://git-scm.com/download/win).' }
$root = Split-Path (Split-Path $git.Source)
while ($root -and -not (Test-Path (Join-Path $root 'bin\bash.exe'))) { $root = Split-Path $root }
if (-not $root) { throw "bash.exe not found above $($git.Source)." }
$bash = Join-Path $root 'bin\bash.exe'
$flags = @($args | Where-Object { $_ -ne '--' })
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'install.sh'))) {
    Push-Location $PSScriptRoot
    try { & $bash ./install.sh @flags } finally { Pop-Location }
} else {
    $quoted = ($flags | ForEach-Object { "'" + ($_ -replace "'", "'\''") + "'" }) -join ' '
    & $bash -lc "set -o pipefail; curl -fsSL https://raw.githubusercontent.com/ojCezarFerreira/grimoire/main/install.sh | sh -s -- $quoted"
}
if ($PSCommandPath) { exit $LASTEXITCODE }  # never exit the caller's session under iex
