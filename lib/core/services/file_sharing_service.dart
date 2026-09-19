import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/providers/backend_providers.dart';
import '../../backend/contracts/reports_backend.dart';
import 'package:uuid/uuid.dart';

final fileSharingServiceProvider = Provider<FileSharingService>((ref) {
  final reportsBackend = ref.watch(reportsBackendProvider);
  return FileSharingService(reportsBackend);
});

class FileSharingService {
  final ReportsBackend _reportsBackend;

  FileSharingService(this._reportsBackend);

  /// يقوم بتنزيل ملف من خادم Traccar (مثل التقارير) ومشاركته فوراً
  Future<void> downloadAndShare(String endpoint,
      {String? filename, Map<String, dynamic>? queryParameters}) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // إنشاء اسم ملف فريد لتجنب التعارض
      final safeFilename =
          filename ?? 'report_${const Uuid().v4().substring(0, 8)}.xlsx';
      final savePath = '${tempDir.path}/$safeFilename';

      // تنزيل الملف عبر ReportsBackend
      final result = await _reportsBackend.downloadLegacyReport(endpoint, queryParameters);
      
      await result.fold(
        (error) => throw Exception(error.code),
        (bytes) async {
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          
          if (await file.exists()) {
            await Share.shareXFiles([XFile(savePath)], text: 'مشاركة الملف المرفق');
          } else {
            throw Exception('لم يتم العثور على الملف بعد التنزيل');
          }
        },
      );
    } catch (e) {
      throw Exception('فشل في تنزيل ومشاركة الملف: $e');
    }
  }
}
