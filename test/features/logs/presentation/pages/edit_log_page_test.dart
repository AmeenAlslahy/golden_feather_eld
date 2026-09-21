import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/edit_log_page.dart';
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  
  @override
  Future<bool> login({required String username, required String password, String? serverUrl}) async => true;
  
  @override
  void forceLogout() {}
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<void> checkAuthStatus() async {}
  
  @override
  void clearError() {}
}

// A simple widget to get WidgetRef
class TestWidget extends ConsumerWidget {
  final void Function(WidgetRef) onRef;
  const TestWidget({required this.onRef, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onRef(ref);
    return const SizedBox.shrink();
  }
}

void main() {
  group('EditLogPage — audit trail attribution (LEGAL-007)', () {
    testWidgets('resolveDriverIdForAudit uses the real driverId from auth session', (tester) async {
      // Arrange
      final user = User(
        id: 'driver-42',
        fullName: 'Ahmed',
        email: 'ahmed@demo.com',
        username: 'ahmed',
        role: UserRole.fieldWorker,
        createdAt: DateTime.now(),
      );

      final mockAuthState = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

      WidgetRef? capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(mockAuthState)),
          ],
          child: MaterialApp(
            home: TestWidget(
              onRef: (ref) => capturedRef = ref,
            ),
          ),
        ),
      );

      // Act
      final driverId = resolveDriverIdForAudit(capturedRef!);

      // Assert
      expect(driverId, equals('driver-42'));
    });
  });
}
