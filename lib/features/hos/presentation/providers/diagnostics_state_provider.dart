import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/diagnostics/diagnostics_engine.dart';

final diagnosticsStateProvider = StreamProvider<DiagnosticsState>((ref) {
  final engine = ref.watch(diagnosticsEngineProvider);
  return engine.stateStream;
});
