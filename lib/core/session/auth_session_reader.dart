import 'auth_session.dart';

/// Narrow session contract used by the HTTP layer and sync dispatch.
///
/// The auth feature owns persistence; core only needs to read the current
/// session and its credential generation.
abstract interface class AuthSessionReader {
  Future<AuthSession?> getSession();

  int get credentialGeneration;
}
