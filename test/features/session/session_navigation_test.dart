import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// P0 Stage 1 corrections — navigation isolation probe.
///
/// Mirrors the app's router shape exactly: a single root [navigatorKey],
/// an auth-driven `redirect` (unprotected → /login), and a user page opened
/// with an imperative `Navigator.push(MaterialPageRoute)` as done in
/// `dvir_list_page.dart`, `log_detail_page.dart`, `home_page.dart`
/// (`ChangeStatusPage`) and others.
///
/// Answers: does `router.go('/login')` after logout remove an
/// imperatively pushed user page, or does A-data stay visible (and
/// back-navigable) in B's session?
class _FakeAuth extends ChangeNotifier {
  bool loggedIn = true;
  void logout() {
    loggedIn = false;
    notifyListeners();
  }
}

GoRouter _router(_FakeAuth auth) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.loggedIn && loc != '/login') return '/login';
      if (auth.loggedIn && loc == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open-user-page'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('A-DATA')),
                  ),
                ),
              ),
              child: const Text('HOME'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('LOGIN')),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets(
      'NAV-01: imperative user page must not survive logout redirect to login',
      (tester) async {
    final auth = _FakeAuth();
    final router = _router(auth);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    // A opens a user-specific page imperatively (A-data on screen).
    await tester.tap(find.byKey(const Key('open-user-page')));
    await tester.pumpAndSettle();
    expect(find.text('A-DATA'), findsOneWidget);

    // Logout → app calls router.go(login); redirect also fires via listener.
    auth.logout();
    router.go('/login');
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget,
        reason: 'login screen must be shown after logout');
    expect(find.text('A-DATA'), findsNothing,
        reason: 'CONTAINMENT: pushed A page must be removed on logout');

    // System back must not resurrect A's page: nothing left to pop.
    expect(router.canPop(), isFalse,
        reason: 'no A route may remain in the stack after logout');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('A-DATA'), findsNothing,
        reason: 'back button must not return to A page');
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
