<#
.SYNOPSIS
  Linter script for features/logs.
  TODO (Sprint 4): Upgrade to proper Dart `custom_lint` package.

.DESCRIPTION
  This script is intended to run in CI (and locally if needed).
  It enforces the rule: No `DateTime.now()` in `features/logs`,
  excluding specific allowed files (Category B - Fallbacks).
#>

$ErrorActionPreference = "Stop"

$searchPath = "lib/features/logs"
$excludeList = @(
    "log_edit.dart",
    "daily_log.dart",
    "log_model.dart",
    "log_local_data_source.dart",
    "log_event_tile.dart" # Comment
)

Write-Host "Running lint: no_datetime_now_in_features..."

# Get all dart files in features/logs
$files = Get-ChildItem -Path $searchPath -Recurse -Filter "*.dart"

$hasError = $false

foreach ($file in $files) {
    if ($excludeList -contains $file.Name) {
        continue
    }

    $content = Get-Content $file.FullName
    $lineNumber = 1
    foreach ($line in $content) {
        if ($line -match "DateTime\.now\(\)") {
            Write-Host "::error file=$($file.FullName),line=$lineNumber::Found prohibited use of DateTime.now() in $($file.Name). Use timeAuthorityProvider instead."
            $hasError = $true
        }
        $lineNumber++
    }
}

if ($hasError) {
    Write-Host "Lint failed. Please fix the above errors."
    exit 1
} else {
    Write-Host "Lint passed!"
    exit 0
}
