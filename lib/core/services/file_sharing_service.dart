import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../network/network_providers.dart';
import 'package:uuid/uuid.dart';

final fileSharingServiceProvider = Provider<FileSharingService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FileSharingService(apiClient);
});

class FileSharingService {
  final ApiClient _apiClient;

  FileSharingService(this._apiClient);

  /// يقوم بتنزيل ملف من خادم Traccar (مثل التقارير) ومشاركته فوراً
  Future<void> downloadAndShare(String endpoint,
      {String? filename, Map<String, dynamic>? queryParameters}) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // إنشاء اسم ملف فريد لتجنب التعارض
      final safeFilename =
          filename ?? 'report_${const Uuid().v4().substring(0, 8)}.xlsx';
      final savePath = '${tempDir.path}/$safeFilename';

      // تنزيل الملف عبر ApiClient (الذي يحتوي أصلاً على Auth Token)
      await _apiClient.downloadFile(endpoint, savePath,
          queryParameters: queryParameters);

      // التأكد من وجود الملف ثم مشاركته
      final file = File(savePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(savePath)], text: 'مشاركة الملف المرفق');
      } else {
        throw Exception('لم يتم العثور على الملف بعد التنزيل');
      }
    } catch (e) {
      throw Exception('فشل في تنزيل ومشاركة الملف: $e');
    }
  }
}
