import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/config/runtime_selection.dart';

void main() {
  test('production ignores a saved mock preference', () {
    final choice = resolveRuntimeBackend(
      environment: AppEnvironment.production,
      buildBaseUrl: 'https://snsoft.cloud',
      savedServerUrl: 'https://old.example',
      savedBackendType: 'mock',
    );

    expect(choice.useMock, isFalse);
    expect(choice.serverUrl, 'https://old.example');
  });

  test('development may use a saved mock override', () {
    final choice = resolveRuntimeBackend(
      environment: AppEnvironment.development,
      buildBaseUrl: 'https://snsoft.cloud',
      savedServerUrl: '',
      savedBackendType: 'mock',
    );

    expect(choice.useMock, isTrue);
    expect(choice.serverUrl, 'https://snsoft.cloud');
  });

  test('empty saved URL falls back to the build URL, then the known host', () {
    final fromBuild = resolveRuntimeBackend(
      environment: AppEnvironment.staging,
      buildBaseUrl: 'https://build.example',
      savedServerUrl: '',
      savedBackendType: 'eld',
    );
    final lastResort = resolveRuntimeBackend(
      environment: AppEnvironment.staging,
      buildBaseUrl: '',
      savedServerUrl: '  ',
      savedBackendType: 'eld',
    );

    expect(fromBuild.serverUrl, 'https://build.example');
    expect(lastResort.serverUrl, fallbackServerOrigin);
  });

  test('backend type does not come from the host name', () {
    expect(
      resolveBackendType(
        configuredType: 'eld',
        savedConfigType: 'traccar',
        storedType: 'traccar',
      ),
      'eld',
    );
    expect(
      resolveBackendType(
        configuredType: null,
        savedConfigType: null,
        storedType: 'demo.traccar.org',
      ),
      'traccar',
    );
  });
}
