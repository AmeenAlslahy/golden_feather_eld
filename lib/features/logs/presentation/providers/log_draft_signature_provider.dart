import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import 'package:signature/signature.dart';

import '../../../../domain/shared/value_objects.dart';
import '../../data/codecs/signature_draft_codec.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/repositories/log_repository.dart';

/// يدير مسودة التوقيع لكل سجل يومي بالذاكرة مع الحفظ الدائم على الجهاز
class LogDraftSignatureNotifier extends StateNotifier<List<Point>> {
  final DailyLogId _logId;
  final LogRepository _repository;

  LogDraftSignatureNotifier(this._logId, this._repository) : super(const []) {
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final json = await _repository.getDraftSignature(_logId);
      if (json != null && json.isNotEmpty) {
        final points = SignatureDraftCodec.decodePoints(json);
        if (points.isNotEmpty && state.isEmpty) {
          state = List.unmodifiable(points);
        }
      }
    } catch (error) {
      // المسودة المحلية احتياطية — الفشل لا يكسر التوقيع، لكن يُسجَّل.
      AppLogger.warning('Draft signature load failed: $error');
    }
  }

  void updateDraft(List<Point> points) {
    if (identical(state, points)) return;
    state = List.unmodifiable(points);
    if (points.isEmpty) {
      _repository.deleteDraftSignature(_logId);
    } else {
      _repository.saveDraftSignature(
        _logId,
        SignatureDraftCodec.encodePoints(points),
      );
    }
  }

  void clearDraft() {
    state = const [];
    _repository.deleteDraftSignature(_logId);
  }
}

/// موفر يدير مسودة التوقيع بالذاكرة ويزامنها مع التخزين المحلي، دون autoDispose
/// حتى لا تضيع مسودة السائق عند التنقل بين الشاشات أو عند تدمير عناصر الواجهة.
final logDraftSignatureProvider =
    StateNotifierProvider.family<
      LogDraftSignatureNotifier,
      List<Point>,
      DailyLogId
    >((ref, logId) {
      final repository = ref.watch(logRepositoryProvider);
      return LogDraftSignatureNotifier(logId, repository);
    });
