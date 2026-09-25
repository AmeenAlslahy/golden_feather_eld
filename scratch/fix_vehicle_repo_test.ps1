$filePath = "d:\Flutter projects\golden_feather_eld\test\features\vehicle\data\repositories\vehicle_repository_impl_test.dart"
$content = Get-Content $filePath
$newContent = $content | ForEach-Object {
    if ($_ -match "import 'package:golden_feather_eld/core/services/local_storage_service.dart';") {
        "import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';"
    } elseif ($_ -match "class MockLocalStorageService extends Mock implements LocalStorageService {}") {
        "class MockHardwareBackend extends Mock implements HardwareBackend {}"
    } elseif ($_ -match "late MockLocalStorageService mockStorage;") {
        "  late MockHardwareBackend mockHardwareBackend;"
    } elseif ($_ -match "mockStorage = MockLocalStorageService\(\);") {
        "    mockHardwareBackend = MockHardwareBackend();"
    } elseif ($_ -match "localDataSource: mockStorage,") {
        "      hardwareBackend: mockHardwareBackend,"
    } else {
        $_
    }
}
$newContent | Set-Content $filePath
