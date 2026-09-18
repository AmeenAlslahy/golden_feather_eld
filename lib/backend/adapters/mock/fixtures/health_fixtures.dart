/// Static fixtures for [MockHealthBackend].
///
/// **Rule:** These match the shape returned by the real backend,
/// as documented in the Swagger spec (tags: "14. System Health").
library;

const healthDetailedFixture = <String, dynamic>{
  'database': {
    'status': 'connected',
    'latencyMs': 12,
  },
  'storage': {
    'writable': true,
    'freeSpaceMb': 512,
  },
  'scheduler': {
    'status': 'running',
    'jobsActive': 3,
  },
  'timestamp': '2026-01-15T10:30:00Z',
};
