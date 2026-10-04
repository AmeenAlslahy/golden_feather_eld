# Architecture enforcement script (PowerShell version for Windows).
# Mirrors scripts/check_architecture.sh.
#
# Modes
# -----
#   default    Hard-fail on untagged package-import violations and Dio leaks.
#              Relative-import violations are REPORTED but do not fail the gate.
#   -Strict    Relative-import violations also fail (target mode after the
#              cross-feature refactor waves land).
#
# Lines carrying `// ignore_architecture` are treated as acknowledged:
# listed under ACKNOWLEDGED, never counted as failures.
#
# NOTE: this script now resolves RELATIVE imports as well. The previous
# version only matched `package:golden_feather_eld/...` imports, so the
# majority of cross-feature/upward violations (relative form) were invisible.

param([switch]$Strict)

$ErrorActionPreference = "Stop"

$hardCount = 0
$warnCount = 0
$taggedCount = 0

function Fail($msg) {
    Write-Host "X $msg" -ForegroundColor Red
    $script:hardCount++
}

function Warn($msg) {
    Write-Host "! $msg" -ForegroundColor Yellow
    $script:warnCount++
}

function Acknowledged($msg) {
    $script:taggedCount++
    Write-Host "  acknowledged: $msg"
}

function Pass($msg) {
    Write-Host "OK $msg" -ForegroundColor Green
}

function Resolve-ImportTarget([string]$sourceFile, [string]$imp) {
    # Returns the normalized absolute path for a relative import,
    # or $null for external/dart/package imports (package handled separately).
    $dir = Split-Path $sourceFile -Parent
    $full = [System.IO.Path]::GetFullPath((Join-Path $dir $imp))
    return $full -replace '\\', '/'
}

function RegionOf([string]$pathIn) {
    # Normalize: forward slashes, then reduce any absolute path to its
    # lib/-relative form so both package imports and resolved relative
    # imports classify identically.
    $path = $pathIn -replace '\\', '/'
    if ($path -match '/lib/') { $path = 'lib/' + ($path -replace '^.*?/lib/', '') }
    if ($path -like 'lib/core/*') { return 'core' }
    if ($path -like 'lib/domain/*') { return 'domain' }
    if ($path -like 'lib/backend/*') { return 'backend' }
    if ($path -like 'lib/app/*') { return 'app' }
    if ($path -like 'lib/features/*') {
        $rest = $path.Substring('lib/features/'.Length)
        return 'feature:' + ($rest -split '/')[0]
    }
    return 'root'
}

# ============================================================================
# Rule 1: No Dio imports outside lib/backend/
# ============================================================================

Write-Host "-> Rule 1: no package:dio outside lib/backend/"

$dioViolations = Get-ChildItem -Path lib -Recurse -Filter *.dart |
    Select-String -Pattern "import 'package:dio" |
    Where-Object { $_.Path -notmatch 'lib[\\/]backend[\\/]' }

if ($dioViolations) {
    foreach ($v in $dioViolations) {
        if ($v.Line -match '// ignore_architecture') {
            Acknowledged "dio leak - $($v.Path):$($v.LineNumber)"
        } else {
            Fail "Dio imported outside backend: $($v.Path):$($v.LineNumber)"
        }
    }
} else {
    Pass "No Dio imports outside backend"
}

# ============================================================================
# Rules 2 + 3: upward imports and cross-feature imports
# (package: and relative: - relative was previously invisible to this script)
# ============================================================================

Write-Host ""
Write-Host "-> Rule 2: no upward imports (core/domain/backend)"
Write-Host "-> Rule 3: no cross-feature imports"

$upwardHard = 0
$crossPkgHard = 0
$crossRel = 0
$crossPairs = @{}

$importRegex = 'import\s+[''"]([^''"]+)[''"]'

foreach ($file in (Get-ChildItem -Path lib -Recurse -Filter *.dart)) {
    $srcRegion = RegionOf ($file.FullName -replace '\\', '/' -replace '^.*/lib/', 'lib/')
    foreach ($m in (Select-String -Path $file.FullName -Pattern $importRegex)) {
        $imp = [regex]::Match($m.Line, $importRegex).Groups[1].Value
        $tagged = $m.Line -match '// ignore_architecture'

        $tgtRegion = $null
        $kind = 'external'
        if ($imp -like 'package:golden_feather_eld/*') {
            $tgtRegion = RegionOf ('lib/' + $imp.Substring('package:golden_feather_eld/'.Length))
            $kind = 'package'
        }
        elseif ($imp -like './*' -or $imp -like '../*') {
            $tgtRegion = RegionOf (Resolve-ImportTarget $file.FullName $imp)
            $kind = 'relative'
        }
        if ($null -eq $tgtRegion) { continue }

        $label = "$($file.FullName):$($m.LineNumber)"

        # Rule 2: upward imports.
        $isUpward = $false
        if ($srcRegion -eq 'core' -and ($tgtRegion -eq 'domain' -or $tgtRegion -eq 'backend' -or $tgtRegion -eq 'app' -or $tgtRegion -like 'feature:*')) { $isUpward = $true }
        if ($srcRegion -eq 'domain' -and ($tgtRegion -eq 'backend' -or $tgtRegion -eq 'app' -or $tgtRegion -like 'feature:*')) { $isUpward = $true }
        if ($srcRegion -eq 'backend' -and ($tgtRegion -eq 'app' -or $tgtRegion -like 'feature:*')) { $isUpward = $true }

        if ($isUpward) {
            if ($tagged) {
                Acknowledged "upward ($srcRegion) - $label"
            }
            elseif ($kind -eq 'package' -or $Strict) {
                Fail "$srcRegion/ imports upward: $label -> $imp"
                $upwardHard++
            }
            else {
                Warn "$srcRegion/ imports upward (relative): $label -> $imp"
            }
            continue
        }

        # Rule 3: cross-feature imports.
        if ($srcRegion -like 'feature:*' -and $tgtRegion -like 'feature:*') {
            $srcFeat = $srcRegion.Substring('feature:'.Length)
            $tgtFeat = $tgtRegion.Substring('feature:'.Length)
            if ($srcFeat -eq $tgtFeat) { continue }

            $pair = "$srcFeat->$tgtFeat"
            if (-not $crossPairs.ContainsKey($pair)) { $crossPairs[$pair] = 0 }
            $crossPairs[$pair]++

            if ($tagged) {
                Acknowledged "cross-feature $pair - $label"
            }
            elseif ($kind -eq 'package') {
                Fail "features/$srcFeat/ imports another feature (package): $label -> $imp"
                $crossPkgHard++
            }
            elseif ($Strict) {
                Fail "features/$srcFeat/ imports another feature (relative): $label -> $imp"
                $crossRel++
            }
            else {
                Warn "features/$srcFeat/ imports another feature (relative): $label -> $imp"
                $crossRel++
            }
        }
    }
}

if ($upwardHard -eq 0) { Pass "No untagged upward imports (package or relative)" }
if ($crossPkgHard -eq 0) { Pass "No untagged package cross-feature imports" }

Write-Host ""
Write-Host "-> Relative cross-feature summary (informational; fails under -Strict):"
if ($crossPairs.Count -eq 0) { Write-Host "  none" }
else {
    $crossPairs.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value)"
    }
}

# ============================================================================
# Summary
# ============================================================================

Write-Host ""
Write-Host "=============================="
Write-Host "acknowledged via // ignore_architecture: $taggedCount"
Write-Host "relative violations (warn-only; fail under -Strict): $warnCount"

if ($hardCount -eq 0) {
    Write-Host "Architecture checks passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$hardCount violation(s) found" -ForegroundColor Red
    exit 1
}
