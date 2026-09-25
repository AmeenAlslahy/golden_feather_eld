$testDir = "d:\Flutter projects\golden_feather_eld\test"
$files = Get-ChildItem -Path $testDir -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $modified = $false

    $newContent = $content | ForEach-Object {
        $line = $_
        
        if ($line -match "package:golden_feather_eld/core/domain/") {
            $line = $line -replace "package:golden_feather_eld/core/domain/", "package:golden_feather_eld/domain/"
            $modified = $true
        }
        
        if ($line -match "package:golden_feather_eld/backend/base/") {
            $line = $line -replace "package:golden_feather_eld/backend/base/", "package:golden_feather_eld/backend/core/"
            $modified = $true
        }

        if ($line -match "package:golden_feather_eld/app/providers/app_repository_providers.dart") {
            # Let's just remove this import, and rely on dart fix if needed, or add multiple specific imports.
            # Actually, it's safer to comment it out and let dart fix complain, or replace it with the new provider paths if we know them.
            # I will replace it with the likely paths.
            $line = "import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';`nimport 'package:golden_feather_eld/features/tracking/data/repositories/tracking_repository_impl.dart';`nimport 'package:golden_feather_eld/features/vehicle/data/repositories/vehicle_repository_impl.dart';"
            $modified = $true
        }

        if ($line -match "import 'package:golden_feather_eld/domain/shared/speed.dart';") {
             $line = ""
             $modified = $true
        }
        
        if ($line -match "package:golden_feather_eld/features/auth/data/models/user_model.dart") {
             $line = "import 'package:golden_feather_eld/features/auth/domain/entities/user_model.dart';"
             $modified = $true
        }

        $line
    }

    if ($modified) {
        $newContent | Set-Content $file.FullName
    }
}
