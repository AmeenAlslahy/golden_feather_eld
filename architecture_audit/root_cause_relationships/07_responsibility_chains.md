# 07 — سلاسل الملكية (Responsibility Chains)

> تتبع UI → Riverpod → Repository → Adapter → Dio لستة مسارات، مع الانحرافات الفعلية.

## W1 — تسجيل الدخول (الأقرب للمعيار)

```
auth_page ──validate──▶ login_form ──▶ authStateProvider.login()
  ──▶ LoginUseCase (تحقق شكلي) ──▶ AuthRepositoryImpl.login()
      ──▶ AuthBackend.login ──▶ EldAuthBackend (URL مطلق + POST /api/session)
      ──▶ AuthSessionDto ──▶ saveSession/saveUser (آمن)
  ──▶ SessionEpoch.bump() ──▶ app.dart يُبطل 3 مزودات HOS
```

- **الملكية واضحة** في كل حلقة. الانحراف الوحيد: تحقق شكلي مكرر (form + use-case).

## W2 — تغيير حالة HOS (ثلاث طبقات قرار)

```
change_status_page ──▶ ChangeStatusNotifier.submit()
  ├─ فحص-1 (provider): moving/permission/annotation
  ──▶ HosNotifier.changeStatus()
      ├─ فحص-2 (engine): validateManualTransition
      ──▶ DutyStatusTracker.submitManualChange()
          ├─ _legalRefusal (وقت/جلسة)
          ──▶ StatusDashboardBackend.updateDutyStatus ──▶ Dio
          ├─ شبكي؟ → _applyManualLocal + SyncEngine.enqueue
          └─ نجاح → _applyManualLocal + dashboard snapshot
  ──▶ statusDashboardProvider.applyServerDashboard (تغذية فورية)
```

- **الغموض:** أي "فحص" هو المرجع؟ (provider أم engine). **التكرار:** فحص الحركة مرتين.
- **الانحراف:** `_applyManualLocal` تُستدعى من مسار تلقائي (`manualTransition` عبر أحداث ELD) بلا أي فحص — وهذا ما جعل توصية "أضف return" خاطئة.

## W3 — إرسال السجلات (نقطة التحول الآمنة)

```
send_logs_page ──▶ inspectionProvider.sendLogs(driverId, method, comment)
  ──▶ InspectionRepositoryImpl.sendLogs()
      ├─ online → backend.sendLogs/emailLogs ──▶ Dio
      └─ offline → _logsOwnedBy + _isVerifiedFor ──▶ generateAndSave
          ──▶ _invalidIdentifyingFields ──▶ OFFLINE_GENERATED أو Left + حذف
```

- **الملكية الآن صريحة** (بعد EC-0.2a): ملكية مُتحقَّقة شرط الدخول، والتحقق اللاحق شرط الإعلان.
- **الانحراف المتبقي:** التحقق اللاحق غير واعٍ بالاقتباس (C8 موثّق) — البوابة أضعف من المعلن.

## W4 — تقديم DVIR (الهوية في المكان الخطأ)

```
dvir_form_page._handleSubmit ──▶ حل deviceId (4 مستويات، آخرها RegExp)
  ──▶ dvirProvider.createReport(report) ──▶ DvirRepositoryImpl.submitDvirReport
      ──▶ DvirBackend.create ──▶ Dio
```

- **الغموض:** من يملك "هوية المركبة"؟ الصفحة تحلّها، والمخطط يرفض اختراعها (`dvir_mappers:119-121`) — **القاعدة والخرق في ملفين متجاورين**.
- **الانحراف:** `DvirReport.deviceId` يُبنى في العرض من `dashboard/vehicleProvider` مباشرة.

## W5 — تبديل السائق (سياج ناقص)

```
codriver_page ──▶ CoDriverNotifier.switchDrivers()
  ──▶ CoDriverRepositoryImpl.switchPrimary() ──▶ DriverSessionBackend ──▶ Dio
  ──▶ _refreshCurrent() (بلا سياج)
```

- **الغموض:** `_loadDrivers` مسيّج و`switchDrivers` لا — نفس الملف، نفس الخطر، معاملتان مختلفتان.
- **الانحراف:** `_cachedDrivers` static تحت السياج (COD-001 المتبقي).

## W6 — تتبع القيادة (التنسيق المبعثر)

```
app_initializer ──▶ trackingService (مثال A، override)
trackingOrchestratorProvider ──▶ 4 مستمعين ──▶ telemetry/hardwareBackend ──▶ Dio
trackingRepositoryProvider ──▶ trackingServiceFullProvider (مثال B) ──▶ Traccar SDK
quick_actions ──▶ مثال A (start/stop/sos)
```

- **الغموض:** أي مثال هو "الخدمة"؟ الإجابة: لا يوجد — **مفهوم واحد بمثالين**.
- **الانحراف:** `TraccarNativeClientImpl()` يُبنى يدوياً في الإقلاع متجاوزاً المزود الواعي بالبيئة.

## جدول الغموض

| النقطة | المسارات المتأثرة |
|---|---|
| أين يُفحص؟ (provider أم engine أم tracker) | W2 |
| من يملك الهوية؟ (صفحة أم مخطط أم مستودع) | W4 |
| أي مثيل هو الخدمة؟ | W6 |
| أي رد يُقبَل بعد انتقال؟ (مسيّج/غير مسيّج) | W5, W1 (مسيّج) مقابل dashboard/dvir/logs (لا) |
| أي ملف نظامي يُعلَن؟ (قبل/بعد التحقق) | W3 (مُحل جزئياً) |
| أي خطأ يُعرض؟ (خام أم مصنّف) | الكل (17 موقعاً خاماً) |
