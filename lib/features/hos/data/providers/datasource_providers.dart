/// Composition Root for HOS feature data sources.
/// **ARCH-HIGH-01 fix:** Data source providers live here, not in the data source files.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ports/hos_storage_port.dart';
import '../datasources/hos_local_data_source.dart';

/// Provides the HosStoragePort implementation (backed by Hive).
final hosLocalDataSourceProvider = Provider<HosStoragePort>((ref) {
  return HosLocalDataSourceImpl();
});
