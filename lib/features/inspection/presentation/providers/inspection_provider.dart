import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/inspection_repository_providers.dart';
import '../../domain/repositories/inspection_repository.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/provider_cache.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../domain/inspection_transfer.dart';
import '../../../../l10n/app_localizations.dart';

// --- State ---

/// حالة التفتيش — جواب سؤالين فقط:
/// 1) هل نحن في وضع التفتيش؟ ([isInspectionMode] + [isPinLocked])
/// 2) ماذا نعرض الآن؟ ([cycle] + [selectedDayIndex] + [log])
///
/// الكتابة تمر حصراً عبر تحولات [InspectionNotifier] المسماة؛ هذه
/// الصفحة بيانات، والقراءة تتم من أسماء التحولات لا من copyWith.
class InspectionState {
  final bool isInspectionMode;
  final bool isPinLocked;

  /// رمز الخروج — يبقى في الذاكرة حتى يخرج السائق (SRS 7.5).
  final String? pinCode;
  final List<DotInspectionCycleDay> cycle;

  /// اليوم المعروض ضمن [cycle] — يتقدم مع [log] في commit واحد.
  final int selectedDayIndex;
  final DotInspectionLog? log;

  /// تحميل مسار البدء (startInspection) — لا يخفي شاشة تفتيش نشطة.
  final bool isLoading;

  /// تحميل يوم بديل — يحفظ آخر زوج صالح معروضاً بدل إخفاء الشاشة.
  final bool isDayLoading;

  /// خطأ lifecycle (بدء/إرسال) — النص جاهز للعرض.
  final String? error;

  /// خطأ تحميل/تطابق اليوم فقط — منفصل عن [error].
  final String? dayError;

  /// نص الخادم عند قبول نقل السجلات (شاشة Send Logs).
  final String? transferMessage;

  const InspectionState({
    this.isInspectionMode = false,
    this.isPinLocked = false,
    this.pinCode,
    this.cycle = const [],
    this.selectedDayIndex = 0,
    this.log,
    this.isLoading = false,
    this.isDayLoading = false,
    this.error,
    this.dayError,
    this.transferMessage,
  });

  /// المنفذ الميكانيكي الوحيد للكتابة — لا تستدعِها خارج تحولات
  /// [InspectionNotifier]؛ الأعلام الـ `clear*` تفرّق "امسح" عن "أبقِ".
  InspectionState copyWith({
    bool? isInspectionMode,
    bool? isPinLocked,
    String? pinCode,
    List<DotInspectionCycleDay>? cycle,
    int? selectedDayIndex,
    DotInspectionLog? log,
    bool clearLog = false,
    bool? isLoading,
    bool? isDayLoading,
    String? error,
    bool clearError = false,
    String? dayError,
    bool clearDayError = false,
    String? transferMessage,
    bool clearTransferMessage = false,
  }) {
    return InspectionState(
      isInspectionMode: isInspectionMode ?? this.isInspectionMode,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinCode: pinCode ?? this.pinCode,
      cycle: cycle ?? this.cycle,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      log: clearLog ? log : (log ?? this.log),
      isLoading: isLoading ?? this.isLoading,
      isDayLoading: isDayLoading ?? this.isDayLoading,
      error: clearError ? null : (error ?? this.error),
      dayError: clearDayError ? dayError : (dayError ?? this.dayError),
      transferMessage: clearTransferMessage
          ? transferMessage
          : (transferMessage ?? this.transferMessage),
    );
  }
}

/// مزود التفتيش.
///
/// اللغة تُقرأ (`ref.read`) لا تُراقَب: إعادة بناء المزود عند تغيير اللغة
/// كانت تمحو وضع التفتيش والـ PIN في منتصف تفتيش فعلي على الطريق.
final inspectionProvider =
    StateNotifierProvider<InspectionNotifier, InspectionState>((ref) {
      return InspectionNotifier(
        repository: ref.watch(inspectionRepositoryProvider),
        driverId: ref.watch(currentDriverIdProvider) ?? 0,
        loc: lookupAppLocalizations(ref.read(localeProvider)),
      );
    });

final informationPacketProvider =
    FutureProvider.autoDispose<InformationPacketView>((ref) async {
      cacheFor(ref, const Duration(minutes: 5));
      final driverId = ref.watch(currentDriverIdProvider);
      final result = await ref
          .watch(inspectionRepositoryProvider)
          .getInformationPacket(
            driverId: driverId == null || driverId <= 0
                ? null
                : DriverId(driverId),
          );
      return result.fold((error) => throw error, (packet) => packet);
    });

// --- Notifier ---

class InspectionNotifier extends StateNotifier<InspectionState> {
  final InspectionRepository _repository;
  final int _driverId;
  final AppLocalizations _loc;

  InspectionNotifier({
    required InspectionRepository repository,
    required int driverId,
    required AppLocalizations loc,
  }) : _repository = repository,
       _driverId = driverId,
       _loc = loc,
       super(const InspectionState());

  String _message(Failure error) {
    return anyErrorUserMessage(error, loc: _loc);
  }

  // =========================================================================
  // تحولات الحالة المسماة — كل كتابة حالة في هذا الملف من هنا، والقراءة
  // تتم بالأسماء: بدء، نشط، تحميل يوم، التزام يوم، فشل يوم، انتهاء.
  // =========================================================================

  InspectionState _starting() =>
      state.copyWith(isLoading: true, clearError: true, clearLog: true);

  /// رفض قبل أي طلب (تحقق مدخلات) — يمسح رسالة نجاح سابقة.
  InspectionState _refused(String message) => state.copyWith(
    isLoading: false,
    error: message,
    clearTransferMessage: true,
  );

  InspectionState _startFailed(String message) =>
      state.copyWith(isLoading: false, isInspectionMode: false, error: message);

  InspectionState _active({
    required String pin,
    required List<DotInspectionCycleDay> cycle,
    required DotInspectionLog? log,
  }) {
    return state.copyWith(
      isLoading: false,
      isInspectionMode: true,
      isPinLocked: true,
      pinCode: pin,
      cycle: cycle,
      selectedDayIndex: 0,
      log: log,
      clearLog: log == null,
      clearError: true,
      clearDayError: true,
    );
  }

  InspectionState _dayLoadStarted() =>
      state.copyWith(isDayLoading: true, clearDayError: true);

  /// الالتزام الذري: الفهرس والسجل يتحركان معاً أم لا يتحركان.
  InspectionState _dayCommitted(int index, DotInspectionLog log) =>
      state.copyWith(
        selectedDayIndex: index,
        log: log,
        isDayLoading: false,
        clearDayError: true,
      );

  /// فشل تحميل اليوم — آخر زوج صالح يبقى معروضاً (لا clearLog).
  InspectionState _dayFailed(String message) =>
      state.copyWith(isDayLoading: false, dayError: message);

  InspectionState _ended() => const InspectionState();

  InspectionState _sending() => state.copyWith(
    isLoading: true,
    clearError: true,
    clearTransferMessage: true,
  );

  /// فشل نقل — يبقي transferMessage القديمة (سلوك محفوظ حرفياً عن
  /// الكود السابق؛ فصل أخطاء الإرسال لالتزام I8 لاحق).
  InspectionState _sendFailed(String message) =>
      state.copyWith(isLoading: false, error: message);

  InspectionState _sendAccepted(String text) =>
      state.copyWith(isLoading: false, clearError: true, transferMessage: text);

  // =========================================================================
  // الأوامر — الواجهة تستدعي هذه فقط.
  // =========================================================================

  /// بدء وضع التفتيش. الرمز يبقى في الذاكرة حتى يخرج السائق.
  ///
  /// لا نداء لـ `POST /eld/dot-inspection/start` هنا: الوضع حالة واجهة
  /// محلية، والخادم يرفض الاستدعاء في هذه المرحلة (ينقصه حقول المفتش).
  Future<void> startInspection({required String pin}) async {
    state = _starting();

    if (_driverId <= 0) {
      state = _startFailed(_loc.driverSessionMissingSignIn);
      return;
    }

    final driver = DriverId(_driverId);
    final cycleResult = await _repository.getCycle(driverId: driver, days: 8);
    if (!mounted) return;
    final cycle = cycleResult.fold(
      (_) => const <DotInspectionCycleDay>[],
      (days) => days,
    );

    final logResult = cycle.isEmpty
        ? await _repository.getLogs(driverId: driver)
        : await _repository.getLogs(
            driverId: driver,
            date: cycle.first.logDate,
          );
    if (!mounted) return;

    final log = logResult.fold((_) => null, (log) => log);
    if (cycle.isEmpty && log == null) {
      // لا بيانات قابلة للعرض إطلاقاً — لا دخول لوضع التفتيش.
      state = _startFailed(
        logResult.fold(_message, (_) => _loc.errRequestFailed),
      );
      return;
    }

    state = _active(pin: pin, cycle: cycle, log: log);
  }

  /// الخروج بالرمز — تحقق محلي، لا شبكة (SRS 7.5).
  bool exitWithPin(String pin) {
    if (state.pinCode == null || pin != state.pinCode) return false;
    endInspection();
    return true;
  }

  /// تغيير اليوم المعروض — الأمر الوحيد الذي يملك مزامنة index ↔ log.
  ///
  /// العقد (Option A): أثناء التحميل يبقى آخر زوج صالح معروضاً كما هو؛
  /// الاثنان يُكتبان معاً عند نجاح الطلب فقط، وبعد تحقق أن سجل الرد
  /// يخص التاريخ المطلوب فعلاً. الفشل يغيّر dayError وحده.
  Future<void> selectDay(int index) async {
    if (state.isDayLoading) return; // ① لا طلبات متوازية
    if (index < 0 || index >= state.cycle.length) return; // ② الحدود
    if (index == state.selectedDayIndex) return; // ③ اليوم نفسه معروض
    if (_driverId <= 0) return;

    final requestedDate = state.cycle[index].logDate;
    state = _dayLoadStarted(); // ④ آخر زوج صالح يبقى معروضاً

    final result = await _repository.getLogs(
      driverId: DriverId(_driverId),
      date: requestedDate,
    );
    if (!mounted) return;

    result.fold((error) => state = _dayFailed(_message(error)), (log) {
      // ⑤ Backstop ضد الرد القديم/غير المتطابق: لا commit ولا
      // fallback تاريخ — السبب في السجلات فقط، والمستخدم يرى رسالة
      // عامة عبر anyErrorUserMessage.
      if (!_sameCycleDay(log.logDate, requestedDate)) {
        AppLogger.warning(
          'selectDay: response logDate does not match requested cycle '
          'day — refused ($requestedDate)',
        );
        state = _dayFailed(
          _message(const ServerFailure(message: 'day log mismatch')),
        );
        return;
      }
      state = _dayCommitted(index, log); // ⑥ الالتزام الذري
    });
  }

  /// هوية يوم الدورة: مقارنة تقويمية على القيم كما حللها الـ mapper —
  /// كلاهما `DateTime` من نفس حقل `logDate` عبر `JsonPrimitives.asDate`.
  static bool _sameCycleDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// إنهاء التفتيش — يعيد الحالة كاملة إلى الافتراضي.
  void endInspection() {
    state = _ended();
  }

  /// إرسال السجلات (SRS 8.4) — النتيجة تُعرض من state.error /
  /// transferMessage (فصل أخطاء الإرسال إلى شاشة الإرسال نفسها هو
  /// تحسين لاحق مستقل، I8).
  Future<bool> sendLogs(
    TransferMethod method, {
    String? email,
    String? routingCode,
    required String comment,
  }) async {
    if (!isValidInspectionComment(comment)) {
      state = _refused(_loc.inspectionCommentErrorLength);
      return false;
    }
    if (_driverId <= 0) {
      state = _refused(_loc.driverSessionMissingSignIn);
      return false;
    }

    state = _sending();
    final driver = DriverId(_driverId);
    final recipient = email?.trim() ?? '';
    final route = routingCode?.trim();
    final result = await _repository.sendLogs(
      driverId: driver,
      method: method,
      email: recipient.isEmpty ? null : recipient,
      comment: comment.trim(),
      routingCode: (route == null || route.isEmpty) ? null : route,
    );

    if (!mounted) return false;
    return result.fold(
      (error) {
        state = _sendFailed(_message(error));
        return false;
      },
      (outcome) {
        state = outcome.accepted
            ? _sendAccepted(outcome.text)
            : _sendFailed(outcome.text);
        return outcome.accepted;
      },
    );
  }
}
