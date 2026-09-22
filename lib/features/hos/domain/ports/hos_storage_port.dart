/// Domain-facing storage port for HOS data.
///
/// **ARCH-CRIT-01 fix:** This port lives in Domain and defines what
/// the Domain layer *needs* from storage. The implementation
/// (`HosLocalDataSourceImpl`) lives in Data and implements this port.
///
/// This breaks the Domain → Data import violation.
library;

/// Port for persisting HOS violations and diagnostics.
///
/// Implementations may use Hive, SQLite, or any other storage mechanism.
/// The Domain layer depends only on this abstract contract.
abstract class HosStoragePort {
  /// Persist a violation record.
  Future<bool> saveViolation(Map<String, dynamic> violationData);

  /// Retrieve violations for a given [date].
  Future<List<Map<String, dynamic>>> getViolations(DateTime date);

  /// Persist a diagnostic event record.
  Future<bool> saveDiagnostic(Map<String, dynamic> diagnosticData);

  /// Retrieve diagnostics for a given [date].
  Future<List<Map<String, dynamic>>> getDiagnostics(DateTime date);
}
