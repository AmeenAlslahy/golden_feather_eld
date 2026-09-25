$testDir = "d:\Flutter projects\golden_feather_eld\test"
$files = Get-ChildItem -Path $testDir -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $modified = $false

    $newContent = $content | ForEach-Object {
        $line = $_
        
        if ($line -match "import 'package:golden_feather_eld/features/auth/domain/entities/user_model.dart';") {
            $line = "import 'package:golden_feather_eld/core/data/models/user_model.dart';"
            $modified = $true
        }
        if ($line -match "import 'package:golden_feather_eld/features/auth/data/models/user_model.dart';") {
            $line = "import 'package:golden_feather_eld/core/data/models/user_model.dart';"
            $modified = $true
        }

        # For home_page_test.dart and tracking_provider_test.dart missing providers
        if ($line -match "import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';") {
            $line = "import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';`nimport 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';"
            $modified = $true
        }

        if ($line -match "import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';") {
            $line = "import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';`nimport 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_providers.dart';`nimport 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';"
            $modified = $true
        }

        $line
    }

    if ($modified) {
        $newContent | Set-Content $file.FullName
    }
}
