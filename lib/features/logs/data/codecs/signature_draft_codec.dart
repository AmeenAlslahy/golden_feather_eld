import 'dart:convert';
import 'dart:ui';

import 'package:signature/signature.dart';

/// كودك تسلسل وفك تسلسل نقاط التوقيع لحفظ المسودات بدقة واستعادتها دون فقدان أي سكتش.
class SignatureDraftCodec {
  const SignatureDraftCodec._();

  /// تحويل قائمة النقاط إلى نص JSON
  static String encodePoints(List<Point> points) {
    if (points.isEmpty) return '[]';
    final list = points
        .map(
          (p) => {
            'x': p.offset.dx,
            'y': p.offset.dy,
            't': p.type.name,
            'p': p.pressure,
          },
        )
        .toList();
    return jsonEncode(list);
  }

  /// فك تشفير نص JSON واستعادة قائمة النقاط
  static List<Point> decodePoints(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return const [];
      final result = <Point>[];
      for (final item in decoded) {
        if (item is Map) {
          final x = (item['x'] as num?)?.toDouble() ?? 0.0;
          final y = (item['y'] as num?)?.toDouble() ?? 0.0;
          final typeName = item['t'] as String?;
          final type = PointType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => PointType.move,
          );
          final pressure = (item['p'] as num?)?.toDouble() ?? 1.0;
          result.add(Point(Offset(x, y), type, pressure));
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }
}
