# Architecture enforcement script (PowerShell version for Windows).
# Mirrors scripts/check_architecture.sh.

$ErrorActionPreference = "Stop"

$violationCount = 0

function Fail($msg) {
    Write-Host "X $msg" -ForegroundColor Red
    $script:violationCount++
}

function Pass($msg) {
    Write-Host "OK $msg" -ForegroundColor Green
}

# ============================================================================
# Rule 1: No Dio imports outside lib/backend/
# ============================================================================

Write-Host "-> Rule 1: no package:dio outside lib/backend/"

$dioViolations = Get-ChildItem -Path lib -Recurse -Filter *.dart |
    Select-String -Pattern "import 'package:dio" |
    Where-Object {
        $_.Path -notmatch "lib\\backend\\" -and
        $_.Line -notmatch "// ignore_architecture"
    }

if ($dioViolations) {
    $dioViolations | ForEach-Object {
        Fail "Dio imported outside backend: $($_.Path):$($_.LineNumber)"
    }
} else {
    Pass "No Dio imports outside backend"
}

# ============================================================================
# Rule 2: No upward imports
# ============================================================================

Write-Host "`n-> Rule 2: no upward imports"

# core/ must not import from domain, backend, features, app
$coreViolations = Get-ChildItem -Path lib\core -Recurse -Filter *.dart |
    Select-String -Pattern "import 'package:golden_feather_eld/(domain|backend|features|app)/"

if ($coreViolations) {
    $coreViolations | ForEach-Object {
        Fail "core/ imports upward: $($_.Path):$($_.LineNumber)"
    }
} else {
    Pass "core/ has no upward imports"
}

# domain/ must not import from backend, features, app
$domainViolations = Get-ChildItem -Path lib\domain -Recurse -Filter *.dart -ErrorAction SilentlyContinue |
    Select-String -Pattern "import 'package:golden_feather_eld/(backend|features|app)/"

if ($domainViolations) {
    $domainViolations | ForEach-Object {
        Fail "domain/ imports upward: $($_.Path):$($_.LineNumber)"
    }
} else {
    Pass "domain/ has no upward imports"
}

# backend/ must not import from features, app
$backendViolations = Get-ChildItem -Path lib\backend -Recurse -Filter *.dart |
    Select-String -Pattern "import 'package:golden_feather_eld/(features|app)/"

if ($backendViolations) {
    $backendViolations | ForEach-Object {
        Fail "backend/ imports upward: $($_.Path):$($_.LineNumber)"
    }
} else {
    Pass "backend/ has no upward imports"
}

# ============================================================================
# Rule 3: No cross-feature imports
# ============================================================================

Write-Host "`n-> Rule 3: no cross-feature imports"

$featureDirs = Get-ChildItem -Path lib\features -Directory
$crossCount = 0

foreach ($dir in $featureDirs) {
    $feature = $dir.Name
    $violations = Get-ChildItem -Path $dir.FullName -Recurse -Filter *.dart |
        Select-String -Pattern "import 'package:golden_feather_eld/features/" |
        Where-Object {
            $_.Line -notmatch "features/$feature/" -and
            $_.Line -notmatch "// ignore_architecture"
        }

    if ($violations) {
        foreach ($v in $violations) {
            Fail "features/$feature/ imports another feature: $($v.Path):$($v.LineNumber)"
            $script:crossCount++
        }
    }
}

if ($crossCount -eq 0) {
    Pass "No cross-feature imports"
}

# ============================================================================
# Summary
# ============================================================================

Write-Host "`n=============================="
if ($violationCount -eq 0) {
    Write-Host "Architecture checks passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "$violationCount violation(s) found" -ForegroundColor Red
    exit 1
}
