$testDir = "d:\Flutter projects\golden_feather_eld\test"
$files = Get-ChildItem -Path $testDir -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $modified = $false

    $newContent = $content | ForEach-Object {
        $line = $_
        
        if ($line -match "package:golden_feather_eld/domain/entities/") {
            $line = $line -replace "package:golden_feather_eld/domain/entities/", "package:golden_feather_eld/core/domain/entities/"
            $modified = $true
        }

        $line
    }

    if ($modified) {
        $newContent | Set-Content $file.FullName
    }
}
