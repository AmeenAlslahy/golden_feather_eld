import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_feedback.dart';
import 'eld_app_bar.dart';

/// الصفحة الأساسية — كل الصفحات ترث منها للاستفادة من السلوك المشترك.
///
/// **الوراثة (Inheritance):** سلوك واحد يُورَّث بدل تكراره في 43 صفحة.
/// **المزايا:**
/// - هوية موحدة (AppBar + Padding + Background)
/// - معالجة موحدة (loading / error / empty)
/// - لا قيم يدوية — كل شيء من الثيم
abstract class BasePage extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const BasePage({super.key, required this.title, this.actions, this.floatingActionButton});

  /// محتوى الصفحة — على الصفحة الابنة تنفيذه فقط.
  Widget buildBody(BuildContext context);

  /// هل تُظهر زر الرجوع؟
  bool get automaticallyImplyLeading => true;

  /// هل المحتوى قابل للتمرير؟
  bool get scrollable => true;

  /// حشوة الصفحة — موحدة، لا يدوية.
  EdgeInsets get pagePadding => const EdgeInsets.all(AppSpacing.screenPadding);

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: pagePadding, child: buildBody(context));
    return Scaffold(
      appBar: EldAppBar(
        title: title,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: scrollable ? SingleChildScrollView(child: body) : body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// صفحة بحالة غير متزامنة — تحميل/خطأ/فارغ/بيانات.
///
/// **الاستخدام:** وراثة واحدة تغني عن `if (isLoading) ... else if (error) ...`
abstract class AsyncBasePage<T> extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? error;
  final T? data;
  final Future<void> Function()? onRetry;
  final List<Widget>? actions;

  const AsyncBasePage({
    super.key,
    required this.title,
    required this.isLoading,
    this.error,
    this.data,
    this.onRetry,
    this.actions,
  });

  /// يبني محتوى البيانات — يُستدعى فقط عند وجود data.
  Widget buildData(BuildContext context, T data);

  /// رسالة الحالة الفارغة.
  String get emptyMessage => 'لا توجد بيانات';

  /// هل البيانات فارغة؟
  bool isEmpty(T data);

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isLoading) {
      body = const AppLoading.fullscreen(message: 'جاري التحميل...');
    } else if (error != null) {
      body = AppErrorView(message: error!, onRetry: onRetry == null ? null : () => onRetry!());
    } else if (data == null || isEmpty(data as T)) {
      body = AppEmptyView(message: emptyMessage);
    } else {
      body = buildData(context, data as T);
    }

    return Scaffold(
      appBar: EldAppBar(title: title, actions: actions),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: body is AppLoading || body is AppErrorView || body is AppEmptyView
            ? body
            : SingleChildScrollView(child: body),
      ),
    );
  }
}
