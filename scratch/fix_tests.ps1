$trackerTest = "d:\Flutter projects\golden_feather_eld\test\core\engine\tracking\duty_status_tracker_test.dart"
$content = Get-Content $trackerTest
$newContent = $content | ForEach-Object {
    $line = $_
    if ($line -match "speedMph: ,") {
        $line = $line -replace "speedMph: ,", "speedMph: 5.1,"
    }
    if ($line -match "Future<Either<Failure, bool>> certifyLog\({") {
        $line = "  Future<Either<Failure, bool>> certifyLog({required DailyLogId logId, required bool certifiedTrue, required String signatureCertificateId, required bool signatureConfirmation, required int driverId, required String logDate}) {"
    }
    if ($line -match "@override") {
        # we will just remove all @override from MockLogRepository and MockSyncEngine for now, as they are mocks
        # wait, the error says: "The method doesn't override an inherited method".
        # Mock class shouldn't need @override if it's using mocktail properly. But wait, if they manually mock:
        # Actually, if they manually mocked, it's not a mocktail `Mock`?
        # Let's just remove the line if it's exactly `@override` and the next line is what's failing.
    }
    $line
}
# Removing all @override from duty_status_tracker_test.dart is safe if they are invalid, but might remove valid ones.
# The errors were lines 36, 39, 42, 45, 48, 125.
$newContent2 = @()
for ($i = 0; $i -lt $newContent.Count; $i++) {
    if ($newContent[$i] -match "@override") {
        if ($i -eq 32 -or $i -eq 35 -or $i -eq 38 -or $i -eq 41 -or $i -eq 44 -or $i -eq 47 -or $i -eq 124) {
            # Skip invalid overrides (0-indexed so line 33 is 32)
            continue
        }
    }
    $newContent2 += $newContent[$i]
}
$newContent2 | Set-Content $trackerTest

# Fix account domain use case test imports
$accountTest = "d:\Flutter projects\golden_feather_eld\test\features\account\domain\usecases\update_rules_use_case_test.dart"
$content = Get-Content $accountTest
$newContent = $content | ForEach-Object {
    $line = $_
    $line = $line -replace "package:golden_feather_eld/features/account/domain/entities/rules_screen_model.dart", "package:golden_feather_eld/features/account/application/models/rules_screen_model.dart"
    $line = $line -replace "package:golden_feather_eld/features/account/domain/usecases/update_rules_use_case.dart", "package:golden_feather_eld/features/account/application/usecases/update_rules_use_case.dart"
    $line
}
$newContent | Set-Content $accountTest

# Fix auth test
$authTest = "d:\Flutter projects\golden_feather_eld\test\features\auth\presentation\providers\auth_state_provider_test.dart"
$content = Get-Content $authTest
$newContent = $content | ForEach-Object {
    $line = $_
    if ($line -match "mockStorage.setDriverId") {
        $line = $line -replace "mockStorage.setDriverId", "mockStorage.saveDriverId"
    }
    $line
}
$newContent | Set-Content $authTest

# Fix tracking event processor
$trackingEventTest = "d:\Flutter projects\golden_feather_eld\test\features\tracking\domain\usecases\tracking_event_processor_test.dart"
$content = Get-Content $trackingEventTest
$newContent = $content | ForEach-Object {
    $line = $_
    if ($line -match "speedMph\.inMilesPerHour") {
        $line = $line -replace "speedMph\.inMilesPerHour", "speedMph"
    }
    if ($line -match "speedMph: ") {
        # ensure there is a number
        if ($line -match "speedMph: ,") {
            $line = $line -replace "speedMph: ,", "speedMph: 0.0,"
        }
    }
    $line
}
$newContent | Set-Content $trackingEventTest

