# UI Architecture and Design Token Guard Scanner
# Enforces design system token adoption and guards against unapproved UI architecture violations.

param(
    [string]$BaselinePath = "ui_violations_baseline.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BaselinePath)) {
    Write-Host "ERROR: Baseline file '$BaselinePath' not found!" -ForegroundColor Red
    exit 1
}

$rawJson = Get-Content $BaselinePath -Raw
$baselineJson = ConvertFrom-Json $rawJson
$approvedEntries = @{}

foreach ($v in $baselineJson.violations) {
    $approvedKey = "$($v.file)|$($v.rule)"
    $approvedEntries[$approvedKey] = [int]$v.count
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Golden Feather ELD - UI Architecture Baseline Guard " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Loaded baseline: $BaselinePath"

$featureFiles = Get-ChildItem -Path "lib/features" -Recurse -Filter "*.dart" | Where-Object {
    $_.FullName -match "\\presentation\\" -and
    $_.FullName -notmatch "painter" -and
    $_.FullName -notmatch "chart"
}

$detectedViolations = @{}
$violationDetails = @()

foreach ($file in $featureFiles) {
    $lines = Get-Content $file.FullName
    $relPath = $file.FullName.Substring($file.FullName.IndexOf("lib\features")).Replace("\", "/")
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $trimmed = $line.Trim()
        
        # Skip comments
        if ($trimmed.StartsWith("//") -or $trimmed.StartsWith("*") -or $trimmed.StartsWith("/*")) {
            continue
        }
        
        # 1. Hardcoded hex color
        if ($line -match "Color\(0x[0-9a-fA-F]{6,8}\)") {
            $key = "$relPath|hardcoded_hex_color"
            $detectedViolations[$key] = [int]$detectedViolations[$key] + 1
            $violationDetails += [PSCustomObject]@{
                File = $relPath
                Line = $i + 1
                Rule = "hardcoded_hex_color"
                Code = $trimmed
            }
        }
        
        # 2. Direct material semantic color (excluding Colors.transparent)
        if ($line -match "\bColors\.(red|green|blue|orange|amber|yellow|grey|white|black|purple|teal|indigo|cyan|lime|brown|pink)\b") {
            $key = "$relPath|direct_material_semantic_color"
            $detectedViolations[$key] = [int]$detectedViolations[$key] + 1
            $violationDetails += [PSCustomObject]@{
                File = $relPath
                Line = $i + 1
                Rule = "direct_material_semantic_color"
                Code = $trimmed
            }
        }
        
        # 3. Direct AppColors semantic usage in features
        if ($line -match "\bAppColors\.") {
            $key = "$relPath|direct_app_colors_semantic"
            $detectedViolations[$key] = [int]$detectedViolations[$key] + 1
            $violationDetails += [PSCustomObject]@{
                File = $relPath
                Line = $i + 1
                Rule = "direct_app_colors_semantic"
                Code = $trimmed
            }
        }
        
        # 4. Inline numeric fontSize
        if ($line -match "fontSize:\s*\d+(\.\d+)?") {
            $key = "$relPath|inline_numeric_font_size"
            $detectedViolations[$key] = [int]$detectedViolations[$key] + 1
            $violationDetails += [PSCustomObject]@{
                File = $relPath
                Line = $i + 1
                Rule = "inline_numeric_font_size"
                Code = $trimmed
            }
        }
        
        # 5. Raw material button or dialog
        if ($line -match "\b(AlertDialog|TextButton|OutlinedButton|AppBar)\(") {
            $key = "$relPath|raw_material_button_or_dialog"
            $detectedViolations[$key] = [int]$detectedViolations[$key] + 1
            $violationDetails += [PSCustomObject]@{
                File = $relPath
                Line = $i + 1
                Rule = "raw_material_button_or_dialog"
                Code = $trimmed
            }
        }
    }
}

$newViolationsCount = 0
$staleEntriesCount = 0

foreach ($entry in $detectedViolations.GetEnumerator()) {
    $itemKey = $entry.Key
    $detectedCount = $entry.Value
    $parts = $itemKey.Split("|")
    $itemFile = $parts[0]
    $itemRule = $parts[1]
    
    if (-not $approvedEntries.ContainsKey($itemKey)) {
        Write-Host "X NEW VIOLATION: $itemFile has $detectedCount unapproved occurrences of rule '$itemRule'" -ForegroundColor Red
        $newViolationsCount += $detectedCount
    } elseif ($detectedCount -gt $approvedEntries[$itemKey]) {
        $excess = $detectedCount - $approvedEntries[$itemKey]
        Write-Host "X INCREASED VIOLATIONS: $itemFile has $detectedCount occurrences of '$itemRule' (baseline approved: $($approvedEntries[$itemKey]))" -ForegroundColor Red
        $newViolationsCount += $excess
    }
}

foreach ($entry in $approvedEntries.GetEnumerator()) {
    $itemKey = $entry.Key
    $approvedCount = $entry.Value
    $parts = $itemKey.Split("|")
    $itemFile = $parts[0]
    $itemRule = $parts[1]
    
    $actualCount = 0
    if ($detectedViolations.ContainsKey($itemKey)) {
        $actualCount = [int]$detectedViolations[$itemKey]
    }
    
    if ($actualCount -lt $approvedCount) {
        Write-Host "! STALE BASELINE: $itemFile has $actualCount actual occurrences of '$itemRule', but baseline approved $approvedCount. Consider updating baseline." -ForegroundColor Yellow
        $staleEntriesCount++
    }
}

Write-Host "-----------------------------------------------------------------"
Write-Host "Scan Summary:"
Write-Host "  Total Files Scanned:         $($featureFiles.Count)"
Write-Host "  Total Violations Found:      $($violationDetails.Count)"
Write-Host "  New / Unapproved Violations: $newViolationsCount"
Write-Host "  Stale Baseline Entries:      $staleEntriesCount"
Write-Host "-----------------------------------------------------------------"

if ($newViolationsCount -gt 0) {
    Write-Host "FAILED: $newViolationsCount new UI architecture violation(s) detected!" -ForegroundColor Red
    Write-Host "Action Required: Use centralized Design System 2.0 tokens or obtain explicit review to update baseline." -ForegroundColor Yellow
    exit 1
}

Write-Host "PASSED: All detected UI patterns match the reviewed baseline." -ForegroundColor Green
exit 0
