import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/daily_form_rules.dart';
import '../../domain/entities/daily_form_data.dart';
import '../../domain/entities/daily_log.dart';
import 'logs_provider.dart';

/// أسبقية قوائم النموذج اليومي (مقطورات/وثائق شحن) — مصدر واحد يمنع
/// اختلاف تبويب النموذج عن شاشات القوائم:
///
/// سجل اليوم: القيمة الحية ← نموذج الخادم ← صف السجل.
/// سجل سابق: نموذج الخادم ← صف السجل (اللوحة الحية تخص اليوم فقط).
///
/// «القيمة الحية» لا تُقرأ لسجل سابق حتى لا تتسرب قيم يوم إلى يوم آخر.
List<String> resolveFormListItems({
  required LogsState logsState,
  required List<String> liveItems,
  required List<String> Function(DailyFormData form) fromServerForm,
  required List<String> Function(DailyLog log) fromLogRow,
}) {
  final selected = logsState.selectedLog;
  final isToday = selected == null || selected.today;

  if (isToday && liveItems.isNotEmpty) {
    return List<String>.unmodifiable(liveItems);
  }

  final form = logsState.serverForm;
  if (form != null) {
    final values = fromServerForm(form);
    if (values.isNotEmpty) return List<String>.unmodifiable(values);
  }

  if (selected != null) {
    final values = fromLogRow(selected);
    if (values.isNotEmpty) return List<String>.unmodifiable(values);
  }

  return const [];
}

/// فشل عملية إضافة عنصر إلى قائمة نموذج يومي (مقطورات/وثائق شحن —
/// SRS 5.5–5.13). ميزة قد لا تُنتج كل الحالات (المقطورات لا تُنتج
/// tooLong/containsComma مثلاً) — الخريطة الكاملة في قواعد كل ميزة.
enum FormListFailure {
  empty,
  limitReached,
  tooLong,
  containsComma,
  invalidFormat,
  alreadyExists,
}

/// حدث ناتج عن عملية على قائمة نموذج يومي.
enum FormListEvent { none, addedSuccessfully, failed }

/// حالة قائمة نموذج يومي — بنية واحدة للمقطورات ووثائق الشحن (كانتا
/// نسختين متطابقتين).
class FormListState {
  final List<String> items;
  final FormListFailure? failure;
  final FormListEvent event;

  const FormListState({
    required this.items,
    this.failure,
    this.event = FormListEvent.none,
  });

  FormListState copyWith({
    List<String>? items,
    FormListFailure? failure,
    bool clearFailure = false,
    FormListEvent? event,
  }) {
    return FormListState(
      items: items ?? this.items,
      failure: clearFailure ? null : (failure ?? this.failure),
      event: event ?? this.event,
    );
  }
}

/// قواعد إضافة عنصر — الخصائص الفارغة تعطّل الخطوة المقابلة، فتحافظ كل
/// ميزة على **ترتيب فحصها الأصلي حرفياً**:
/// فارغ ← حد العدد ← حد الطول الصريح ← الفاصلة ← صلاحية التسمية ← التكرار.
class FormListRules {
  /// حد عدد العناصر (المقطورات: 5؛ وثائق الشحن: بلا حد).
  final int? maxCount;

  /// حد طول صريح برسالة خاصة (وثائق الشحن: 100؛ المقطورات: ضمن
  /// صلاحية التسمية فقط).
  final int? hardMaxLength;

  /// رفض الفاصلة برسالة خاصة (وثائق الشحن فقط).
  final bool forbidComma;

  /// حد طول تسمية [isFormLabelValid] (50 للمقطورات، 100 للوثائق).
  final int labelMaxLength;

  /// السماح بالشرطة المائلة في التسمية (الوثائق فقط).
  final bool allowSlash;

  const FormListRules({
    this.maxCount,
    this.hardMaxLength,
    this.forbidComma = false,
    required this.labelMaxLength,
    this.allowSlash = false,
  });
}

/// متحكم قوائم نموذج اليوم المشترك: بناء الحالة (سجل سابق ← نموذج
/// الخادم/صف السجل؛ سجل اليوم ← اللوحة الحية)، مسار الإضافة الموحد
/// بترتيب فحص معلن، والحذف. الميزة توفر القواعد ومصادر القراءة/الحفظ
/// فقط — كان المنطق منسوخاً بين المقطورات ووثائق الشحن (مراجعة
/// 2026-10-25).
abstract class FormListNotifier extends AutoDisposeNotifier<FormListState> {
  FormListRules get rules;

  /// عناصر القائمة كما وردت في نموذج الخادم لسجل سابق.
  List<String> savedFromServerForm(DailyFormData form);

  /// عناصر القائمة كما وردت في صف السجل نفسه.
  List<String> savedFromLogRow(DailyLog log);

  /// القيمة الحية من لوحة القيادة لسجل اليوم (تُقرأ بـ watch داخل build).
  String? liveDashboardRaw();

  /// يحفظ القائمة الجديدة في المصدر الصحيح: الحالة الحية لسجل اليوم،
  /// أو نموذج السجل نفسه لأي سجل سابق.
  void persist(List<String> next);

  @override
  FormListState build() {
    final logsState = ref.watch(logsProvider);
    final selected = logsState.selectedLog;
    final liveItems = (selected == null || selected.today)
        ? splitFormList(liveDashboardRaw())
        : const <String>[];

    return FormListState(
      items: List.of(
        resolveFormListItems(
          logsState: logsState,
          liveItems: liveItems,
          fromServerForm: savedFromServerForm,
          fromLogRow: savedFromLogRow,
        ),
      ),
    );
  }

  /// يضيف عنصراً بعد التحقق وفق [rules] بترتيب معلن واحد.
  void addItem(String rawInput) {
    final text = rawInput.trim();
    final failure = _reject(text);
    if (failure != null) {
      state = state.copyWith(failure: failure, event: FormListEvent.failed);
      return;
    }
    persist([...state.items, text]);
    state = state.copyWith(
      clearFailure: true,
      event: FormListEvent.addedSuccessfully,
    );
  }

  /// يحذف العنصر المحدد ويحدّث الحالة المشتركة.
  void removeItem(String value) {
    persist(state.items.where((item) => item != value).toList());
  }

  FormListFailure? _reject(String text) {
    final r = rules;
    if (text.isEmpty) return FormListFailure.empty;
    if (r.maxCount != null && state.items.length >= r.maxCount!) {
      return FormListFailure.limitReached;
    }
    if (r.hardMaxLength != null && text.length > r.hardMaxLength!) {
      return FormListFailure.tooLong;
    }
    if (r.forbidComma && text.contains(',')) {
      return FormListFailure.containsComma;
    }
    if (!isFormLabelValid(text, r.labelMaxLength, allowSlash: r.allowSlash)) {
      return FormListFailure.invalidFormat;
    }
    if (state.items.contains(text)) return FormListFailure.alreadyExists;
    return null;
  }
}
