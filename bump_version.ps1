<#
.SYNOPSIS
    Bumps the version of agentivity_ag_ui, updates CHANGELOG.md, commits, tags and pushes.

.DESCRIPTION
    1. Validates the new semver version.
    2. Updates 'version:' in pubspec.yaml.
    3. Prepends a new entry to CHANGELOG.md.
    4. Runs 'dart analyze lib/' -- aborts on errors.
    5. git add -> commit -> tag -> push (unless -DryRun or -NoPush).

.PARAMETER Version
    New version in X.Y.Z semver format. Required.

.PARAMETER Message
    One-line summary for the CHANGELOG entry (shown as bold header).
    Defaults to a placeholder you can edit before the commit is made.

.PARAMETER DryRun
    Simulate everything; no files are written, no git commands run.

.PARAMETER NoPush
    Commit and tag locally but do not push to the remote.

.PARAMETER NoTag
    Commit but skip creating the git tag.

.PARAMETER NoAnalyze
    Skip 'dart analyze' (useful when toolchain is not on PATH).

.EXAMPLE
    .\bump_version.ps1 0.4.0 "Improved streaming performance"

.EXAMPLE
    .\bump_version.ps1 0.4.0 --DryRun

.EXAMPLE
    .\bump_version.ps1 0.4.0 "Fix SSE reconnect" --NoPush
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version,

    [Parameter(Position = 1)]
    [string]$Message = "",

    [switch]$DryRun,
    [switch]$NoPush,
    [switch]$NoTag,
    [switch]$NoAnalyze
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step   ([string]$text) { Write-Host "`n>>  $text" -ForegroundColor Cyan }
function Write-Ok     ([string]$text) { Write-Host "    OK  $text" -ForegroundColor Green }
function Write-Skip   ([string]$text) { Write-Host "    --  $text" -ForegroundColor DarkGray }
function Write-Dry    ([string]$text) { Write-Host "    (dry) $text" -ForegroundColor Yellow }
function Fail         ([string]$text) { Write-Host "`nERROR: $text" -ForegroundColor Red; exit 1 }

# ── Paths ─────────────────────────────────────────────────────────────────────

$Root      = $PSScriptRoot
$Pubspec   = Join-Path $Root "pubspec.yaml"
$Changelog = Join-Path $Root "CHANGELOG.md"

if (-not (Test-Path $Pubspec))   { Fail "pubspec.yaml not found in $Root" }
if (-not (Test-Path $Changelog)) { Fail "CHANGELOG.md not found in $Root" }

# ── Validate version ──────────────────────────────────────────────────────────

Write-Step "Validating version"

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "Version must be semver X.Y.Z (e.g. 0.4.0). Got: $Version"
}

$PubspecContent = Get-Content $Pubspec -Raw
if ($PubspecContent -notmatch 'version:\s*(\S+)') {
    Fail "Could not find 'version:' field in pubspec.yaml"
}
$OldVersion = $Matches[1]

if ($OldVersion -eq $Version) {
    Fail "New version ($Version) is the same as current ($OldVersion). Nothing to do."
}

Write-Ok "$OldVersion -> $Version"

if ($DryRun) { Write-Host "`n  *** DRY RUN -- no files will be changed ***" -ForegroundColor Yellow }

# ── Check git working tree ────────────────────────────────────────────────────

Write-Step "Checking git status"

$GitStatus = & git status --porcelain 2>&1
$Dirty = $GitStatus | Where-Object { $_ -notmatch '^\s*[MADRCU?!]+\s+(pubspec\.yaml|CHANGELOG\.md)' }
if ($Dirty) {
    Write-Host "   Working tree has uncommitted changes:" -ForegroundColor Yellow
    $Dirty | ForEach-Object { Write-Host "   $_" -ForegroundColor Yellow }
    $Ans = Read-Host "`n   Continue anyway? [y/N]"
    if ($Ans -notmatch '^[Yy]') { Fail "Aborted." }
}

$ExistingTag = & git tag --list "v$Version" 2>&1
if ($ExistingTag) { Fail "Git tag v$Version already exists." }

Write-Ok "Git tree OK"

# ── Update pubspec.yaml ───────────────────────────────────────────────────────

Write-Step "Updating pubspec.yaml"

$NewPubspec = $PubspecContent -replace '(?m)^version:\s*\S+', "version: $Version"

if ($DryRun) {
    Write-Dry "Would write: version: $Version"
} else {
    [System.IO.File]::WriteAllText($Pubspec, $NewPubspec, [System.Text.Encoding]::UTF8)
    Write-Ok "pubspec.yaml updated"
}

# ── Update CHANGELOG.md ───────────────────────────────────────────────────────

Write-Step "Updating CHANGELOG.md"

$Date        = Get-Date -Format "yyyy-MM-dd"
$EntryTitle  = if ($Message) { $Message } else { "Release $Version" }

$NewEntry = "## $Version - $Date`r`n`r`n**$EntryTitle**`r`n`r`n- `r`n`r`n---`r`n`r`n"

$OldChangelog = [System.IO.File]::ReadAllText($Changelog, [System.Text.Encoding]::UTF8)

# Insert after the '# Changelog' heading if present, otherwise prepend.
if ($OldChangelog -match '^(# Changelog\r?\n)') {
    $Heading   = $Matches[1]
    $Remainder = $OldChangelog.Substring($Heading.Length)
    $NewChangelog = $Heading + "`r`n" + $NewEntry + $Remainder
} else {
    $NewChangelog = $NewEntry + $OldChangelog
}

if ($DryRun) {
    Write-Dry "Would prepend CHANGELOG entry for $Version"
} else {
    [System.IO.File]::WriteAllText($Changelog, $NewChangelog, [System.Text.Encoding]::UTF8)
    Write-Ok "CHANGELOG.md updated"
}

# ── dart analyze ──────────────────────────────────────────────────────────────

if ($NoAnalyze) {
    Write-Skip "dart analyze skipped (-NoAnalyze)"
} elseif ($DryRun) {
    Write-Skip "dart analyze skipped in dry-run"
} else {
    Write-Step "Running dart analyze lib/"

    Push-Location $Root
    try {
        $AnalyzeOut = & dart analyze lib/ 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host ($AnalyzeOut -join "`n") -ForegroundColor Red
            Fail "dart analyze found errors. Fix them before bumping the version."
        }
        Write-Ok "No issues found"
    } finally {
        Pop-Location
    }
}

# ── Git commit ────────────────────────────────────────────────────────────────

Write-Step "Committing changes"

$CommitMsg = "chore: bump version to $Version"

if ($DryRun) {
    Write-Dry "Would run: git add pubspec.yaml CHANGELOG.md"
    Write-Dry "Would run: git commit -m `"$CommitMsg`""
} else {
    & git add pubspec.yaml CHANGELOG.md
    & git commit -m $CommitMsg
    if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }
    Write-Ok "Committed: $CommitMsg"
}

# ── Git tag ───────────────────────────────────────────────────────────────────

if ($NoTag) {
    Write-Skip "Git tag skipped (-NoTag)"
} elseif ($DryRun) {
    Write-Dry "Would run: git tag v$Version"
} else {
    Write-Step "Creating tag v$Version"
    & git tag "v$Version"
    if ($LASTEXITCODE -ne 0) { Fail "git tag failed." }
    Write-Ok "Tag created: v$Version"
}

# ── Git push ──────────────────────────────────────────────────────────────────

if ($NoPush) {
    Write-Skip "Push skipped (-NoPush). Run manually when ready:"
    Write-Host "         git push origin HEAD" -ForegroundColor DarkGray
    if (-not $NoTag) {
        Write-Host "         git push origin v$Version" -ForegroundColor DarkGray
    }
} elseif ($DryRun) {
    Write-Dry "Would run: git push origin HEAD"
    if (-not $NoTag) { Write-Dry "Would run: git push origin v$Version" }
} else {
    Write-Step "Pushing to origin"

    & git push origin HEAD
    if ($LASTEXITCODE -ne 0) { Fail "git push failed." }
    Write-Ok "Branch pushed"

    if (-not $NoTag) {
        & git push origin "v$Version"
        if ($LASTEXITCODE -ne 0) { Fail "git push tag failed." }
        Write-Ok "Tag v$Version pushed"
    }
}

# ── Done ──────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  agentivity_ag_ui v$Version done!" -ForegroundColor Green
if (-not $DryRun -and -not $NoPush) {
    Write-Host "  https://github.com/agentivity-labs/agentivity_ag_ui/releases/tag/v$Version" -ForegroundColor DarkGray
}
Write-Host ""
