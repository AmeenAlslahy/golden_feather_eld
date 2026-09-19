$ErrorActionPreference = "Stop"

# 1. Move HosLimits out of hos_calculator.dart to hos_models.dart
$calcPath = "lib/features/hos/domain/engine/hos_calculator.dart"
$modelsPath = "lib/features/hos/domain/engine/hos_models.dart"

$calcContent = Get-Content $calcPath -Raw
# Extract HosLimits
$hosLimitsRegex = "(?s)/// حدود ساعات الخدمة\r?\nclass HosLimits \{.*?\r?\n\}"
$hosLimitsMatch = [regex]::Match($calcContent, $hosLimitsRegex)
if ($hosLimitsMatch.Success) {
    $hosLimitsCode = $hosLimitsMatch.Value
    $calcContent = $calcContent -replace $hosLimitsRegex, ""
    Set-Content -Path $calcPath -Value $calcContent -NoNewline

    $modelsContent = Get-Content $modelsPath -Raw
    $modelsContent = $modelsContent + "`n`n" + $hosLimitsCode + "`n"
    Set-Content -Path $modelsPath -Value $modelsContent -NoNewline
}

# 2. Extract LocationPoint from distance_tracker.dart to core/domain/entities/location_point.dart
$distancePath = "lib/features/hos/domain/engine/tracking/distance_tracker.dart"
$locationPointPath = "lib/core/domain/entities/location_point.dart"
New-Item -ItemType Directory -Force -Path "lib/core/domain/entities" | Out-Null

$distContent = Get-Content $distancePath -Raw
$locPointRegex = "(?s)/// نقطة موقع\r?\nclass LocationPoint \{.*?\r?\n\}"
$locPointMatch = [regex]::Match($distContent, $locPointRegex)
if ($locPointMatch.Success) {
    $locPointCode = $locPointMatch.Value
    $distContent = $distContent -replace $locPointRegex, ""
    $distContent = "import '../../../../../core/domain/entities/location_point.dart';`n" + $distContent
    Set-Content -Path $distancePath -Value $distContent -NoNewline

    Set-Content -Path $locationPointPath -Value $locPointCode -NoNewline
}

# 3. Move hos_models.dart to core/domain/entities/hos_models.dart
$newModelsPath = "lib/core/domain/entities/hos_models.dart"
Move-Item -Path $modelsPath -Destination $newModelsPath

# 4. Global replace of hos_models.dart imports
$oldHosModels = "package:golden_feather_eld/features/hos/domain/engine/hos_models.dart"
$newHosModels = "package:golden_feather_eld/core/domain/entities/hos_models.dart"

Get-ChildItem -Path lib,test -Include *.dart -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $orig = $content

    $content = $content.Replace($oldHosModels, $newHosModels)
    $content = $content.Replace("'../../domain/engine/hos_models.dart'", "'package:golden_feather_eld/core/domain/entities/hos_models.dart'")
    $content = $content.Replace("'../hos_models.dart'", "'package:golden_feather_eld/core/domain/entities/hos_models.dart'")
    $content = $content.Replace("'hos_models.dart'", "'package:golden_feather_eld/core/domain/entities/hos_models.dart'")

    if ($orig -ne $content) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
    }
}

# 5. Fix log_graph.dart (Remove tracking_events_stream_provider, add local one)
$logGraphPath = "lib/features/logs/presentation/widgets/log_graph.dart"
$logGraphContent = Get-Content $logGraphPath -Raw
$logGraphContent = $logGraphContent.Replace("import '../../../tracking/presentation/providers/tracking_events_stream_provider.dart';", "import '../../../../core/services/live_tracking_data_source.dart';`n`nfinal trackingEventsStreamProvider = StreamProvider.autoDispose<EldEvent>((ref) {`n  return ref.watch(liveTrackingDataSourceProvider).events;`n});")
Set-Content -Path $logGraphPath -Value $logGraphContent -NoNewline

# 6. Extract orchestration logic from tracking_provider.dart to app/orchestrators/tracking_orchestrator.dart
$trackingProviderPath = "lib/features/tracking/presentation/providers/tracking_provider.dart"
$trackingContent = Get-Content $trackingProviderPath -Raw

$orchestratorPath = "lib/app/orchestrators/tracking_orchestrator.dart"
New-Item -ItemType Directory -Force -Path "lib/app/orchestrators" | Out-Null

$orchestratorCode = @"
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tracking/presentation/providers/tracking_provider.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/vehicle/presentation/providers/vehicle_provider.dart';
import '../../features/hos/presentation/providers/hos_provider.dart';
import '../../core/domain/entities/hos_models.dart';
import '../../core/utils/logger.dart';

final trackingOrchestratorProvider = Provider<void>((ref) {
  final notifier = ref.read(trackingStateProvider.notifier);

  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (next.status == AuthStatus.unauthenticated &&
        previous?.status == AuthStatus.authenticated) {
      notifier.stopTracking(force: true);
    }
  });

  ref.listen<VehicleState>(vehicleProvider, (previous, next) {
    if (next.selectedVehicle != null &&
        previous?.selectedVehicle != next.selectedVehicle) {
      if (!notifier.isActiveOrLoading) {
        AppLogger.info('🚀 Auto-starting tracking due to vehicle selection');
        notifier.startTracking(skipBatteryCheck: true);
      }
    }
  });

  ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
    if (next is HosEngineReady) {
      final prevStatus =
          (previous is HosEngineReady) ? previous.update.currentStatus : null;
      if (next.update.currentStatus == DutyStatus.driving &&
          prevStatus != DutyStatus.driving) {
        if (!notifier.isActiveOrLoading) {
          AppLogger.info('🚀 Auto-starting tracking because status changed to DRIVING');
          notifier.startTracking(skipBatteryCheck: true);
        }
      }
    }
  });
});
"@
Set-Content -Path $orchestratorPath -Value $orchestratorCode -NoNewline

# Remove the listen blocks from tracking_provider.dart
$listenRegex = "(?s)  // 1\) إيقاف التتبع عند تسجيل الخروج.*?// 3\) بدء التتبع إجبارياً عند تغيير الحالة إلى Driving يدوياً.*?\}\);\r?\n  \}\);"
$trackingContent = $trackingContent -replace $listenRegex, ""

# Remove the unused imports from tracking_provider.dart
$trackingContent = $trackingContent -replace "import '../../../auth/presentation/providers/auth_state_provider.dart';\r?\n", ""
$trackingContent = $trackingContent -replace "import '../../../vehicle/presentation/providers/vehicle_provider.dart';\r?\n", ""
$trackingContent = $trackingContent -replace "import '../../../hos/presentation/providers/hos_provider.dart';\r?\n", ""
$trackingContent = $trackingContent -replace "import '../../../../features/hos/domain/engine/hos_rules_engine.dart';\r?\n", ""

Set-Content -Path $trackingProviderPath -Value $trackingContent -NoNewline

# 7. Add trackingOrchestratorProvider to app_initializer.dart
$appInitPath = "lib/core/services/app_initializer.dart"
$appInitContent = Get-Content $appInitPath -Raw
$appInitContent = "import '../../app/orchestrators/tracking_orchestrator.dart';`n" + $appInitContent
$appInitContent = $appInitContent.Replace("container.read(syncEngineProvider);", "container.read(syncEngineProvider);`n      container.read(trackingOrchestratorProvider);")
Set-Content -Path $appInitPath -Value $appInitContent -NoNewline

Write-Host "Done"
