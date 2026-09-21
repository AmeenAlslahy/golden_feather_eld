import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/diagnostics/diagnostics_engine.dart';
import 'hos_engine_provider.dart';

final diagnosticsStateProvider = StreamProvider<DiagnosticsState>((ref) {
  final engine = ref.watch(diagnosticsEngineProvider);
  return engine.stateStream;
});
