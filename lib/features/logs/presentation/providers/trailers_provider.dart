import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../domain/daily_form_rules.dart';
import 'logs_provider.dart';

/// أسباب فشل عمليات المقطورات وفق قواعد النموذج اليومي (SRS 5.5–5.13).
enum TrailerActionFailure { empty, limitReached, invalidFormat, alreadyExists }

/// حدث ناتج عن عملية على المقطورات.
enum TrailerEvent { none, addedSuccessfully, failed }

/// حالة إدارة المقطورات بالكامل.
class TrailersState {
  final List<String> trailers;
  final TrailerActionFailure? failure;
  final TrailerEvent event;

  const TrailersState({
    required this.trailers,
    this.failure,
    this.event = TrailerEvent.none,
  });

  TrailersState copyWith({
    List<String>? trailers,
    TrailerActionFailure? failure,
    bool clearFailure = false,
    TrailerEvent? event,
  }) {
    return TrailersState(
      trailers: trailers ?? this.trailers,
      failure: clearFailure ? null : (failure ?? this.failure),
      event: event ?? this.event,
    );
  }
}

/// متحكم وموفر إدارة المقطورات المفصول تماماً عن طبقة العرض والـ BuildContext.
class TrailersNotifier extends AutoDisposeNotifier<TrailersState> {
  @override
  TrailersState build() {
    final logsState = ref.watch(logsProvider);
    final selected = logsState.selectedLog;
    if (selected != null && !selected.today) {
      // سجل سابق: المصدر قيمه المحفوظة الخاصة به، لا حالة اللوحة الحية.
      final form = logsState.serverForm;
      return TrailersState(
        trailers: List.of(form?.trailers ?? selected.trailers),
      );
    }
    final raw = ref.watch(dashboardDataProvider.select((d) => d.trailerId));
    return TrailersState(trailers: splitFormList(raw));
  }

  /// يحفظ القائمة الجديدة في المصدر الصحيح: الحالة الحية لسجل اليوم،
  /// أو نموذج السجل نفسه لأي سجل سابق.
  void _persist(List<String> next) {
    final selected = ref.read(logsProvider).selectedLog;
    if (selected != null && !selected.today) {
      ref.read(logsProvider.notifier).updateSelectedFormLists(trailers: next);
      return;
    }
    ref.read(dashboardDataProvider.notifier).updateTrailers(next);
  }

  /// يضيف مقطورة جديدة بعد التحقق من صحتها وحدودها وتحديث الحالة.
  void addTrailer(String rawInput) {
    final text = rawInput.trim();
    if (text.isEmpty) {
      state = state.copyWith(
        failure: TrailerActionFailure.empty,
        event: TrailerEvent.failed,
      );
      return;
    }

    if (state.trailers.length >= 5) {
      state = state.copyWith(
        failure: TrailerActionFailure.limitReached,
        event: TrailerEvent.failed,
      );
      return;
    }

    if (!isFormLabelValid(text, 50)) {
      state = state.copyWith(
        failure: TrailerActionFailure.invalidFormat,
        event: TrailerEvent.failed,
      );
      return;
    }

    if (state.trailers.contains(text)) {
      state = state.copyWith(
        failure: TrailerActionFailure.alreadyExists,
        event: TrailerEvent.failed,
      );
      return;
    }

    _persist([...state.trailers, text]);

    state = state.copyWith(
      clearFailure: true,
      event: TrailerEvent.addedSuccessfully,
    );
  }

  /// يحذف المقطورة المحددة ويحدث الحالة المشتركة.
  void removeTrailer(String trailer) {
    _persist(state.trailers.where((t) => t != trailer).toList());
  }
}

/// موفر إدارة المقطورات
final trailersProvider =
    AutoDisposeNotifierProvider<TrailersNotifier, TrailersState>(
      TrailersNotifier.new,
    );

/// الاسم البديل للتوافق البرمجي الكامل
final trailersControllerProvider = trailersProvider;
