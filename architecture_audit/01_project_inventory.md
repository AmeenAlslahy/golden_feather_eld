# 01 — جرد المشروع الكامل (Project Inventory)

**المشروع:** golden_feather_eld — Golden Feather ELD (Electronic Logging Device)
**التقنيات:** Flutter 3.32+ / Dart 3.8+ · Riverpod 2.5 · Dio 5.4 · go_router 14 · freezed 3 · sqflite · geolocator · Traccar SDK · Firebase
**تاريخ الجرد:** 2026-10-10 19:01

## 1.1 الأرقام الإجمالية

| المؤشر | القيمة |
|---|---|
| إجمالي ملفات Dart في lib/ | **408** |
| ملفات مكتوبة يدوياً (في نطاق التدقيق) | **395** |
| ملفات مولّدة (مستثناة) | **13** |
| إجمالي أسطر الملفات المكتوبة يدوياً | **45447** |
| أسطر غير فارغة | **41147** |
| حواف الاستيراد الداخلية | **1628** |
| دورات استيراد (SCC) | **4** |
| ملاحظات معمارية | **228** |

## 1.2 الملفات المستثناة ومبرراتها

| الملف | السبب |
|---|---|
| `lib/domain/account/driver_account.freezed.dart` (353 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/account/driver_account.g.dart` (62 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/config/server_config.freezed.dart` (159 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/duty_status/status_dashboard.freezed.dart` (1153 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/duty_status/weekly_recap.freezed.dart` (299 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/hardware/telemetry_reading.freezed.dart` (201 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/inspection/dot_inspection.freezed.dart` (879 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/shared/value_objects.freezed.dart` (1539 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/domain/signature/signature.freezed.dart` (175 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/l10n/app_localizations.dart` (5814 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/l10n/app_localizations_ar.dart` (3044 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/l10n/app_localizations_en.dart` (3063 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |
| `lib/l10n/app_localizations_es.dart` (3090 سطر) | كود مولّد (freezed / json_serializable / flutter gen-l10n) |

> **لم يُستثنَ أي ملف مكتوب يدوياً.** جميع الملفات المولّدة أُسقطت من التقييم المعماري كقاعدة، مع فحص إعدادات التوليد (pubspec.yaml, l10n.yaml, uild.yaml, التعليقات التوضيحية reezed/json_serializable) كما هو مطلوب.

## 1.3 التوزيع حسب الطبقة المعمارية

| الطبقة | عدد الملفات | أسطر | ملفات > 300 سطر |
|---|---|---|---|
| **Infra** (`lib/main.dart`, `lib/app.dart`, `lib/routes.dart`, `lib/app/**`, `lib/routes/**`) | 7 | 740 | 0 |
| **Backend** (`lib/backend/**`) | 66 | 5409 |  |
| **Core** (`lib/core/**`) | 83 | 7243 | 4 |
| **Domain مشترك** (`lib/domain/**`) | 9 | 769 | 0 |
| **Features** (`lib/features/**`) | 225 | 31087 | 30 |
| **Root** (مولّد l10n) | 5 | 199 | 0 |

## 1.4 الميزات (Features)

| الميزة | domain | data | presentation | المجموع |
|---|---|---|---|---|
| `about` | 0 | 0 |  (+0 application) |  ⚠️ **بلا domain** |
| `account` | 0 | 0 | 7 (+2 application) | 9 ⚠️ **بلا domain** |
| `auth` | 8 | 3 | 8 (+0 application) | 19 |
| `codriver` | 5 | 2 | 3 (+0 application) | 10 |
| `connection` | 3 | 0 | 13 (+0 application) | 16 |
| `dvir` | 8 | 4 | 13 (+0 application) | 25 |
| `home` | 0 | 0 | 5 (+0 application) | 5 ⚠️ **بلا domain** |
| `hos` | 9 | 4 | 16 (+0 application) | 29 |
| `inspection` | 3 | 4 | 8 (+0 application) | 15 |
| `logs` | 9 | 5 | 28 (+0 application) | 42 |
| `onboarding` | 0 | 0 |  (+0 application) |  ⚠️ **بلا domain** |
| `permissions` | 0 | 0 |  (+0 application) |  ⚠️ **بلا domain** |
| `settings` | 0 | 0 |  (+0 application) |  ⚠️ **بلا domain** |
| `sync` | 8 | 7 | 3 (+0 application) | 18 |
| `tracking` | 7 | 16 | 2 (+0 application) | 25 |
| `vehicle` | 3 | 2 | 3 (+0 application) | 8 |

> ⚠️ ميزتان بلا طبقة domain إطلاقاً: connection وbout/settings/onboarding/permissions (shutdown pages).


## 1.5 قائمة الملفات الكاملة مع أرقام الأسطر

> Gen = ملف مولّد (مستثنى). Declared layer = الطبقة التي يوحي بها المجلد.


### app / routes / root

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 114 | 103 | `lib/app.dart` |
| 2 | 119 | 101 | `lib/app/app_initializer.dart` |
| 3 | 110 | 96 | `lib/app/orchestrators/tracking_orchestrator.dart` |
| 4 | 156 | 137 | `lib/app/services/push_notification_service.dart` |
| 5 | 77 | 68 | `lib/app/services/quick_actions_initializer.dart` |

### backend

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 118 | 97 | `lib/backend/adapters/eld_engine/eld_engine_adapter.dart` |
| 2 | 151 | 135 | `lib/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart` |
| 3 | 27 | 23 | `lib/backend/adapters/eld_engine/mappers/hardware_mapper.dart` |
| 4 | 72 | 64 | `lib/backend/adapters/eld_engine/mappers/json_primitives.dart` |
| 5 | 33 | 32 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart` |
| 6 | 215 | 188 | `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` |
| 7 | 50 | 45 | `lib/backend/adapters/eld_engine/models/certify_dto.dart` |
| 8 | 432 | 401 | `lib/backend/adapters/eld_engine/models/dvir_dto.dart` |
| 9 | 86 | 81 | `lib/backend/adapters/eld_engine/models/readiness_dto.dart` |
| 10 | 103 | 94 | `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` |
| 11 | 29 | 29 | `lib/backend/adapters/eld_engine/models/rules_screen_options.dart` |
| 12 | 81 | 72 | `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` |
| 13 | 200 | 183 | `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart` |
| 14 | 162 | 149 | `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart` |
| 15 | 92 | 85 | `lib/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart` |
| 16 | 89 | 82 | `lib/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart` |
| 17 | 138 | 124 | `lib/backend/adapters/eld_engine/sub/eld_dvir_backend.dart` |
| 18 | 114 | 101 | `lib/backend/adapters/eld_engine/sub/eld_hardware_backend.dart` |
| 19 | 195 | 182 | `lib/backend/adapters/eld_engine/sub/eld_inspection_backend.dart` |
| 20 | 51 | 46 | `lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart` |
| 21 | 34 | 31 | `lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart` |
| 22 | 126 | 119 | `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart` |
| 23 | 83 | 75 | `lib/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart` |
| 24 | 47 | 42 | `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart` |
| 25 | 65 | 63 | `lib/backend/adapters/mock/fixtures/account_fixtures.dart` |
| 26 | 109 | 87 | `lib/backend/adapters/mock/mock_adapter.dart` |
| 27 | 30 | 27 | `lib/backend/adapters/mock/sub/mock_account_backend.dart` |
| 28 | 51 | 46 | `lib/backend/adapters/mock/sub/mock_auth_backend.dart` |
| 29 | 131 | 119 | `lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart` |
| 30 | 44 | 38 | `lib/backend/adapters/mock/sub/mock_driver_session_backend.dart` |
| 31 | 45 | 39 | `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart` |
| 32 | 74 | 63 | `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` |
| 33 | 70 | 63 | `lib/backend/adapters/mock/sub/mock_hardware_backend.dart` |
| 34 | 195 | 182 | `lib/backend/adapters/mock/sub/mock_inspection_backend.dart` |
| 35 | 72 | 68 | `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart` |
| 36 | 49 | 41 | `lib/backend/adapters/mock/sub/mock_signature_backend.dart` |
| 37 | 191 | 178 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart` |
| 38 | 39 | 35 | `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart` |
| 39 | 21 | 17 | `lib/backend/adapters/mock/sub/mock_vehicle_backend.dart` |
| 40 | 17 | 15 | `lib/backend/contracts/account_backend.dart` |
| 41 | 29 | 25 | `lib/backend/contracts/auth_backend.dart` |
| 42 | 51 | 41 | `lib/backend/contracts/contract_enums.dart` |
| 43 | 72 | 61 | `lib/backend/contracts/daily_logs_backend.dart` |
| 44 | 31 | 25 | `lib/backend/contracts/driver_session_backend.dart` |
| 45 | 35 | 30 | `lib/backend/contracts/duty_status_backend.dart` |
| 46 | 50 | 39 | `lib/backend/contracts/dvir_backend.dart` |
| 47 | 37 | 31 | `lib/backend/contracts/hardware_backend.dart` |
| 48 | 65 | 56 | `lib/backend/contracts/inspection_backend.dart` |
| 49 | 10 | 9 | `lib/backend/contracts/raw_json.dart` |
| 50 | 15 | 13 | `lib/backend/contracts/rules_screen_backend.dart` |
| 51 | 13 | 12 | `lib/backend/contracts/signature_backend.dart` |
| 52 | 20 | 17 | `lib/backend/contracts/status_dashboard_backend.dart` |
| 53 | 27 | 24 | `lib/backend/contracts/unidentified_events_backend.dart` |
| 54 | 12 | 9 | `lib/backend/contracts/vehicle_backend.dart` |
| 55 | 61 | 42 | `lib/backend/core/backend_adapter.dart` |
| 56 | 94 | 81 | `lib/backend/core/backend_identity.dart` |
| 57 | 19 | 17 | `lib/backend/core/backend_kind.dart` |
| 58 | 129 | 111 | `lib/backend/core/backend_registry.dart` |
| 59 | 7 | 6 | `lib/backend/http/api_config.dart` |
| 60 | 7 | 6 | `lib/backend/http/api_response.dart` |
| 61 | 150 | 137 | `lib/backend/http/eld_endpoints.dart` |
| 62 | 144 | 130 | `lib/backend/http/interceptors/auth_interceptor.dart` |
| 63 | 134 | 124 | `lib/backend/http/interceptors/request_logger.dart` |
| 64 | 67 | 57 | `lib/backend/http/interceptors/time_drift_interceptor.dart` |
| 65 | 82 | 70 | `lib/backend/providers/backend_network_providers.dart` |
| 66 | 117 | 99 | `lib/backend/providers/backend_providers.dart` |

### core

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 106 | 90 | `lib/core/config/app_environment.dart` |
| 2 | 99 | 93 | `lib/core/config/hos_configuration.dart` |
| 3 | 61 | 53 | `lib/core/config/runtime_selection.dart` |
| 4 | 8 | 7 | `lib/core/config/server_config_provider.dart` |
| 5 | 79 | 67 | `lib/core/config/server_config_store.dart` |
| 6 | 53 | 45 | `lib/core/constants/app_constants.dart` |
| 7 | 5 | 5 | `lib/core/constants/channel_constants.dart` |
| 8 | 41 | 30 | `lib/core/constants/fmcsa_constants.dart` |
| 9 | 15 | 13 | `lib/core/constants/storage_constants.dart` |
| 10 | 99 | 91 | `lib/core/data/models/user_model.dart` |
| 11 | 19 | 17 | `lib/core/design_system.dart` |
| 12 | 33 | 25 | `lib/core/di/app_providers.dart` |
| 13 | 11 | 9 | `lib/core/di/auth_local_data_source_provider.dart` |
| 14 | 6 | 5 | `lib/core/di/id_generator_provider.dart` |
| 15 | 316 | 278 | `lib/core/domain/entities/hos_models.dart` |
| 16 | 12 | 11 | `lib/core/domain/entities/location_point.dart` |
| 17 | 77 | 64 | `lib/core/domain/entities/user.dart` |
| 18 | 565 | 504 | `lib/core/error/app_error.dart` |
| 19 | 77 | 57 | `lib/core/error/exception.dart` |
| 20 | 136 | 113 | `lib/core/error/failure.dart` |
| 21 | 99 | 92 | `lib/core/error/user_facing_message.dart` |
| 22 | 18 | 15 | `lib/core/events/app_events.dart` |
| 23 | 18 | 15 | `lib/core/events/eld_events_provider.dart` |
| 24 | 112 | 94 | `lib/core/extensions/context_extensions.dart` |
| 25 | 41 | 34 | `lib/core/localization/locale_provider.dart` |
| 26 | 345 | 318 | `lib/core/network/api_client.dart` |
| 27 | 109 | 93 | `lib/core/network/api_config.dart` |
| 28 | 157 | 138 | `lib/core/network/api_response.dart` |
| 29 | 66 | 56 | `lib/core/network/core_providers.dart` |
| 30 | 228 | 204 | `lib/core/network/error_mapper.dart` |
| 31 | 34 | 30 | `lib/core/network/lenient_json_transformer.dart` |
| 32 | 29 | 27 | `lib/core/network/network_guard.dart` |
| 33 | 57 | 49 | `lib/core/network/network_info.dart` |
| 34 | 24 | 21 | `lib/core/providers/driver_rules_provider.dart` |
| 35 | 104 | 86 | `lib/core/result/result.dart` |
| 36 | 97 | 83 | `lib/core/services/bluetooth_service.dart` |
| 37 | 31 | 26 | `lib/core/services/local_database_service.dart` |
| 38 | 225 | 190 | `lib/core/services/local_storage_service.dart` |
| 39 | 107 | 98 | `lib/core/services/tracking_config_storage_service.dart` |
| 40 | 40 | 32 | `lib/core/services/user_preferences_storage_service.dart` |
| 41 | 50 | 44 | `lib/core/services/utc_sync_service.dart` |
| 42 | 31 | 28 | `lib/core/session/session_epoch.dart` |
| 43 | 29 | 21 | `lib/core/storage/adapters/flutter_secure_storage_adapter.dart` |
| 44 | 17 | 13 | `lib/core/storage/ports/secure_storage_port.dart` |
| 45 | 12 | 10 | `lib/core/storage/storage_providers.dart` |
| 46 | 155 | 112 | `lib/core/theme/app_colors.dart` |
| 47 | 71 | 64 | `lib/core/theme/app_decorations.dart` |
| 48 | 31 | 22 | `lib/core/theme/app_radius.dart` |
| 49 | 28 | 25 | `lib/core/theme/app_shadows.dart` |
| 50 | 18 | 16 | `lib/core/theme/app_spacing.dart` |
| 51 | 244 | 234 | `lib/core/theme/app_styles.dart` |
| 52 | 222 | 211 | `lib/core/theme/app_theme.dart` |
| 53 | 48 | 40 | `lib/core/theme/app_theme_provider.dart` |
| 54 | 75 | 67 | `lib/core/theme/app_typography.dart` |
| 55 | 34 | 30 | `lib/core/theme/press_feedback.dart` |
| 56 | 56 | 50 | `lib/core/time/monotonic_time_authority.dart` |
| 57 | 70 | 61 | `lib/core/time/time_authority.dart` |
| 58 | 31 | 29 | `lib/core/time/time_authority_provider.dart` |
| 59 | 45 | 41 | `lib/core/time/time_formatter.dart` |
| 60 | 230 | 197 | `lib/core/time/trusted_time_provider.dart` |
| 61 | 16 | 15 | `lib/core/utils/app_date_utils.dart` |
| 62 | 21 | 20 | `lib/core/utils/duration_format.dart` |
| 63 | 12 | 9 | `lib/core/utils/id_generator.dart` |
| 64 | 52 | 50 | `lib/core/utils/localization_helper.dart` |
| 65 | 37 | 31 | `lib/core/utils/logger.dart` |
| 66 | 18 | 16 | `lib/core/utils/provider_cache.dart` |
| 67 | 61 | 58 | `lib/core/utils/repository_helper.dart` |
| 68 | 8 | 7 | `lib/core/utils/status_color_helper.dart` |
| 69 | 194 | 174 | `lib/core/widgets/app_button.dart` |
| 70 | 116 | 104 | `lib/core/widgets/app_feedback.dart` |
| 71 | 232 | 218 | `lib/core/widgets/app_signature_canvas.dart` |
| 72 | 96 | 89 | `lib/core/widgets/app_status_badge.dart` |
| 73 | 53 | 49 | `lib/core/widgets/app_status_pill.dart` |
| 74 | 125 | 121 | `lib/core/widgets/app_text_field.dart` |
| 75 | 101 | 92 | `lib/core/widgets/connection_status_indicator.dart` |
| 76 | 58 | 55 | `lib/core/widgets/critical_error_app.dart` |
| 77 | 24 | 21 | `lib/core/widgets/dashed_line_painter.dart` |
| 78 | 41 | 38 | `lib/core/widgets/eld_card.dart` |
| 79 | 73 | 69 | `lib/core/widgets/eld_date_paginator.dart` |
| 80 | 187 | 178 | `lib/core/widgets/eld_events_table.dart` |
| 81 | 348 | 289 | `lib/core/widgets/eld_graph_grid.dart` |
| 82 | 63 | 60 | `lib/core/widgets/eld_info_row.dart` |
| 83 | 51 | 46 | `lib/core/widgets/eld_retry_view.dart` |

### domain (shared)

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 36 | 31 | `lib/domain/account/driver_account.dart` |
| 2 | 353 | 274 | `lib/domain/account/driver_account.freezed.dart` *(Gen — excluded)* |
| 3 | 62 | 56 | `lib/domain/account/driver_account.g.dart` *(Gen — excluded)* |
| 4 | 85 | 71 | `lib/domain/config/server_config.dart` |
| 5 | 159 | 114 | `lib/domain/config/server_config.freezed.dart` *(Gen — excluded)* |
| 6 | 99 | 84 | `lib/domain/duty_status/duty_status_code.dart` |
| 7 | 202 | 167 | `lib/domain/duty_status/status_dashboard.dart` |
| 8 | 1153 | 847 | `lib/domain/duty_status/status_dashboard.freezed.dart` *(Gen — excluded)* |
| 9 | 45 | 40 | `lib/domain/duty_status/weekly_recap.dart` |
| 10 | 299 | 211 | `lib/domain/duty_status/weekly_recap.freezed.dart` *(Gen — excluded)* |
| 11 | 47 | 39 | `lib/domain/hardware/telemetry_reading.dart` |
| 12 | 201 | 158 | `lib/domain/hardware/telemetry_reading.freezed.dart` *(Gen — excluded)* |
| 13 | 142 | 131 | `lib/domain/inspection/dot_inspection.dart` |
| 14 | 879 | 709 | `lib/domain/inspection/dot_inspection.freezed.dart` *(Gen — excluded)* |
| 15 | 70 | 56 | `lib/domain/shared/value_objects.dart` |
| 16 | 1539 | 1032 | `lib/domain/shared/value_objects.freezed.dart` *(Gen — excluded)* |
| 17 | 43 | 35 | `lib/domain/signature/signature.dart` |
| 18 | 175 | 132 | `lib/domain/signature/signature.freezed.dart` *(Gen — excluded)* |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 330 | 314 | `lib/features/about/presentation/pages/about_page.dart` |

### features/*/application

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 70 | 59 | `lib/features/account/application/models/rules_screen_model.dart` |
| 2 | 62 | 51 | `lib/features/account/application/usecases/update_rules_use_case.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 352 | 336 | `lib/features/account/presentation/pages/account_page.dart` |
| 2 | 150 | 139 | `lib/features/account/presentation/pages/info_packet_page.dart` |
| 3 | 502 | 475 | `lib/features/account/presentation/pages/instructions_page.dart` |
| 4 | 502 | 476 | `lib/features/account/presentation/pages/rules_page.dart` |
| 5 | 559 | 538 | `lib/features/account/presentation/pages/user_manual_page.dart` |
| 6 | 157 | 136 | `lib/features/account/presentation/providers/account_provider.dart` |
| 7 | 25 | 21 | `lib/features/account/presentation/providers/rules_screen_provider.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 137 | 117 | `lib/features/auth/data/datasources/auth_local_data_source.dart` |
| 2 | 65 | 58 | `lib/features/auth/data/models/auth_session_dto.dart` |
| 3 | 195 | 175 | `lib/features/auth/data/repositories/auth_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 53 | 44 | `lib/features/auth/domain/entities/auth_session.dart` |
| 2 | 8 | 8 | `lib/features/auth/domain/entities/value_objects/email_regex.dart` |
| 3 | 41 | 36 | `lib/features/auth/domain/entities/value_objects/login_identifier.dart` |
| 4 | 21 | 18 | `lib/features/auth/domain/entities/value_objects/password.dart` |
| 5 | 20 | 16 | `lib/features/auth/domain/repositories/auth_repository.dart` |
| 6 | 15 | 12 | `lib/features/auth/domain/usecases/check_auth_status_usecase.dart` |
| 7 | 37 | 32 | `lib/features/auth/domain/usecases/login_usecase.dart` |
| 8 | 12 | 9 | `lib/features/auth/domain/usecases/logout_usecase.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 160 | 150 | `lib/features/auth/presentation/pages/auth_page.dart` |
| 2 | 97 | 86 | `lib/features/auth/presentation/pages/splash_page.dart` |
| 3 | 14 | 12 | `lib/features/auth/presentation/providers/auth_mode_provider.dart` |
| 4 | 3 | 2 | `lib/features/auth/presentation/providers/auth_providers.dart` |
| 5 | 330 | 292 | `lib/features/auth/presentation/providers/auth_state_provider.dart` |
| 6 | 33 | 26 | `lib/features/auth/presentation/providers/login_form_provider.dart` |
| 7 | 133 | 125 | `lib/features/auth/presentation/widgets/forgot_password_form.dart` |
| 8 | 134 | 121 | `lib/features/auth/presentation/widgets/login_form.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 20 | 16 | `lib/features/codriver/data/providers/codriver_repository_providers.dart` |
| 2 | 144 | 136 | `lib/features/codriver/data/repositories/codriver_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 51 | 46 | `lib/features/codriver/domain/current_codriver.dart` |
| 2 | 10 | 8 | `lib/features/codriver/domain/entities/codriver.dart` |
| 3 | 15 | 12 | `lib/features/codriver/domain/repositories/codriver_repository.dart` |
| 4 | 40 | 38 | `lib/features/codriver/domain/role_switch_guard.dart` |
| 5 | 56 | 51 | `lib/features/codriver/domain/team_status.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 541 | 521 | `lib/features/codriver/presentation/pages/codriver_page.dart` |
| 2 | 238 | 219 | `lib/features/codriver/presentation/providers/codriver_provider.dart` |
| 3 | 41 | 37 | `lib/features/codriver/presentation/providers/team_status_provider.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 151 | 136 | `lib/features/connection/domain/connectivity_status.dart` |
| 2 | 15 | 14 | `lib/features/connection/domain/entities/hardware_alert.dart` |
| 3 | 75 | 67 | `lib/features/connection/domain/hardware_readiness.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 13 | 12 | `lib/features/connection/presentation/mac_address_validation.dart` |
| 2 | 101 | 92 | `lib/features/connection/presentation/pages/diagnostics_page.dart` |
| 3 | 529 | 492 | `lib/features/connection/presentation/pages/eld_connection_page.dart` |
| 4 | 83 | 74 | `lib/features/connection/presentation/providers/hardware_alerts_provider.dart` |
| 5 | 42 | 39 | `lib/features/connection/presentation/providers/hardware_status_provider.dart` |
| 6 | 41 | 37 | `lib/features/connection/presentation/widgets/diagnostics/active_malfunction_actions.dart` |
| 7 | 72 | 65 | `lib/features/connection/presentation/widgets/diagnostics/event_card.dart` |
| 8 | 58 | 51 | `lib/features/connection/presentation/widgets/diagnostics/stat_row.dart` |
| 9 | 57 | 51 | `lib/features/connection/presentation/widgets/dialogs/manual_mode_reason_dialog.dart` |
| 10 | 78 | 74 | `lib/features/connection/presentation/widgets/eld_connectivity_panel.dart` |
| 11 | 13 | 12 | `lib/features/connection/presentation/widgets/eld_diagnostics_section.dart` |
| 12 | 117 | 113 | `lib/features/connection/presentation/widgets/eld_readiness_panel.dart` |
| 13 | 131 | 124 | `lib/features/connection/presentation/widgets/manual_recording_section.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 91 | 83 | `lib/features/dvir/data/mappers/dvir_defect_mappers.dart` |
| 2 | 208 | 197 | `lib/features/dvir/data/mappers/dvir_mappers.dart` |
| 3 | 17 | 14 | `lib/features/dvir/data/providers/dvir_repository_providers.dart` |
| 4 | 388 | 368 | `lib/features/dvir/data/repositories/dvir_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 37 | 32 | `lib/features/dvir/domain/defect_enums.dart` |
| 2 | 64 | 56 | `lib/features/dvir/domain/dvir_catalog.dart` |
| 3 | 33 | 30 | `lib/features/dvir/domain/dvir_list_summary.dart` |
| 4 | 9 | 8 | `lib/features/dvir/domain/dvir_signature.dart` |
| 5 | 8 | 7 | `lib/features/dvir/domain/dvir_vehicle.dart` |
| 6 | 73 | 68 | `lib/features/dvir/domain/entities/dvir_defect.dart` |
| 7 | 266 | 246 | `lib/features/dvir/domain/entities/dvir_report.dart` |
| 8 | 43 | 36 | `lib/features/dvir/domain/repositories/dvir_repository.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 9 | 8 | `lib/features/dvir/presentation/extensions/dvir_catalog_extensions.dart` |
| 2 | 37 | 34 | `lib/features/dvir/presentation/extensions/dvir_status_extensions.dart` |
| 3 | 486 | 446 | `lib/features/dvir/presentation/pages/dvir_detail_page.dart` |
| 4 | 690 | 636 | `lib/features/dvir/presentation/pages/dvir_form_page.dart` |
| 5 | 340 | 328 | `lib/features/dvir/presentation/pages/dvir_list_page.dart` |
| 6 | 325 | 299 | `lib/features/dvir/presentation/providers/dvir_provider.dart` |
| 7 | 257 | 244 | `lib/features/dvir/presentation/widgets/active_defects_section.dart` |
| 8 | 58 | 52 | `lib/features/dvir/presentation/widgets/defect_card.dart` |
| 9 | 153 | 141 | `lib/features/dvir/presentation/widgets/defects_modal.dart` |
| 10 | 199 | 183 | `lib/features/dvir/presentation/widgets/dvir_form_components.dart` |
| 11 | 498 | 458 | `lib/features/dvir/presentation/widgets/dvir_form_sections.dart` |
| 12 | 74 | 69 | `lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart` |
| 13 | 81 | 77 | `lib/features/dvir/presentation/widgets/status_modal.dart` |
| 14 | 219 | 206 | `lib/features/home/presentation/pages/home_page.dart` |
| 15 | 224 | 202 | `lib/features/home/presentation/providers/dashboard_provider.dart` |
| 16 | 66 | 63 | `lib/features/home/presentation/providers/home_provider.dart` |
| 17 | 100 | 92 | `lib/features/home/presentation/widgets/eld_bottom_nav.dart` |
| 18 | 149 | 146 | `lib/features/home/presentation/widgets/eld_drawer.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 14 | 12 | `lib/features/hos/data/providers/hos_audit_providers.dart` |
| 2 | 15 | 12 | `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` |
| 3 | 58 | 52 | `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` |
| 4 | 115 | 108 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 113 | 94 | `lib/features/hos/domain/engine/hos_calculator.dart` |
| 2 | 240 | 207 | `lib/features/hos/domain/engine/hos_rules_engine.dart` |
| 3 | 128 | 106 | `lib/features/hos/domain/engine/hos_state_machine.dart` |
| 4 | 555 | 494 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` |
| 5 | 6 | 5 | `lib/features/hos/domain/repositories/hos_audit_repository.dart` |
| 6 | 20 | 17 | `lib/features/hos/domain/repositories/status_dashboard_repository.dart` |
| 7 | 15 | 12 | `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` |
| 8 | 15 | 12 | `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` |
| 9 | 18 | 15 | `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 32 | 27 | `lib/features/hos/presentation/duty_change_message.dart` |
| 2 | 52 | 48 | `lib/features/hos/presentation/extensions/duty_status_l10n.dart` |
| 3 | 232 | 212 | `lib/features/hos/presentation/pages/change_status_page.dart` |
| 4 | 117 | 113 | `lib/features/hos/presentation/pages/recap_page.dart` |
| 5 | 118 | 103 | `lib/features/hos/presentation/pages/status_dashboard_page.dart` |
| 6 | 397 | 353 | `lib/features/hos/presentation/providers/change_status_provider.dart` |
| 7 | 83 | 71 | `lib/features/hos/presentation/providers/hos_engine_provider.dart` |
| 8 | 159 | 140 | `lib/features/hos/presentation/providers/hos_provider.dart` |
| 9 | 38 | 31 | `lib/features/hos/presentation/providers/recap_provider.dart` |
| 10 | 145 | 127 | `lib/features/hos/presentation/providers/status_dashboard_providers.dart` |
| 11 | 57 | 54 | `lib/features/hos/presentation/widgets/driving_lock_screen.dart` |
| 12 | 39 | 35 | `lib/features/hos/presentation/widgets/location_display_widget.dart` |
| 13 | 150 | 139 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` |
| 14 | 365 | 331 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` |
| 15 | 93 | 84 | `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` |
| 16 | 70 | 62 | `lib/features/hos/presentation/widgets/status_option_tiles.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 120 | 112 | `lib/features/inspection/data/mappers/inspection_mappers.dart` |
| 2 | 15 | 14 | `lib/features/inspection/data/providers/inspection_repository_providers.dart` |
| 3 | 266 | 248 | `lib/features/inspection/data/repositories/inspection_repository_impl.dart` |
| 4 | 208 | 177 | `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 58 | 50 | `lib/features/inspection/domain/inspection_transfer.dart` |
| 2 | 43 | 36 | `lib/features/inspection/domain/repositories/inspection_repository.dart` |
| 3 | 31 | 28 | `lib/features/inspection/domain/transfer_audit.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 73 | 65 | `lib/features/inspection/presentation/pages/dot_inspection_page.dart` |
| 2 | 145 | 136 | `lib/features/inspection/presentation/pages/inspection_active_view.dart` |
| 3 | 210 | 197 | `lib/features/inspection/presentation/pages/inspection_start_view.dart` |
| 4 | 332 | 309 | `lib/features/inspection/presentation/pages/send_logs_page.dart` |
| 5 | 60 | 51 | `lib/features/inspection/presentation/providers/dot_inspection_providers.dart` |
| 6 | 367 | 319 | `lib/features/inspection/presentation/providers/inspection_provider.dart` |
| 7 | 176 | 159 | `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` |
| 8 | 259 | 242 | `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 322 | 291 | `lib/features/logs/data/datasources/log_local_data_source.dart` |
| 2 | 143 | 134 | `lib/features/logs/data/models/daily_log_dto.dart` |
| 3 | 133 | 121 | `lib/features/logs/data/models/log_model.dart` |
| 4 | 25 | 21 | `lib/features/logs/data/providers/log_repository_providers.dart` |
| 5 | 539 | 498 | `lib/features/logs/data/repositories/log_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 93 | 83 | `lib/features/logs/domain/daily_form_rules.dart` |
| 2 | 100 | 89 | `lib/features/logs/domain/entities/audit_entry.dart` |
| 3 | 32 | 29 | `lib/features/logs/domain/entities/daily_form_data.dart` |
| 4 | 27 | 24 | `lib/features/logs/domain/entities/daily_form_update.dart` |
| 5 | 251 | 236 | `lib/features/logs/domain/entities/daily_log.dart` |
| 6 | 69 | 63 | `lib/features/logs/domain/entities/log_readiness.dart` |
| 7 | 57 | 49 | `lib/features/logs/domain/log_edit.dart` |
| 8 | 93 | 85 | `lib/features/logs/domain/repositories/log_repository.dart` |
| 9 | 36 | 31 | `lib/features/logs/domain/saved_form_status.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 122 | 105 | `lib/features/logs/presentation/controllers/edit_log_controller.dart` |
| 2 | 68 | 58 | `lib/features/logs/presentation/controllers/form_tab_controller.dart` |
| 3 | 93 | 88 | `lib/features/logs/presentation/pages/audit_trail_page.dart` |
| 4 | 433 | 407 | `lib/features/logs/presentation/pages/edit_log_page.dart` |
| 5 | 401 | 382 | `lib/features/logs/presentation/pages/inspection_preview_page.dart` |
| 6 | 220 | 211 | `lib/features/logs/presentation/pages/log_detail_page.dart` |
| 7 | 239 | 225 | `lib/features/logs/presentation/pages/logs_list_page.dart` |
| 8 | 170 | 160 | `lib/features/logs/presentation/pages/shipping_documents_page.dart` |
| 9 | 121 | 117 | `lib/features/logs/presentation/pages/suggested_events_page.dart` |
| 10 | 170 | 160 | `lib/features/logs/presentation/pages/trailers_page.dart` |
| 11 | 505 | 479 | `lib/features/logs/presentation/pages/unidentified_events_page.dart` |
| 12 | 10 | 9 | `lib/features/logs/presentation/providers/audit_trail_provider.dart` |
| 13 | 193 | 163 | `lib/features/logs/presentation/providers/certify_log_provider.dart` |
| 14 | 66 | 59 | `lib/features/logs/presentation/providers/edit_log_form_provider.dart` |
| 15 | 5 | 4 | `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` |
| 16 | 352 | 310 | `lib/features/logs/presentation/providers/logs_provider.dart` |
| 17 | 170 | 154 | `lib/features/logs/presentation/providers/unidentified_events_provider.dart` |
| 18 | 113 | 105 | `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` |
| 19 | 346 | 324 | `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` |
| 20 | 144 | 134 | `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` |
| 21 | 59 | 55 | `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` |
| 22 | 383 | 358 | `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` |
| 23 | 166 | 156 | `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` |
| 24 | 101 | 86 | `lib/features/logs/presentation/widgets/log_graph.dart` |
| 25 | 61 | 57 | `lib/features/logs/presentation/widgets/status_radio_group.dart` |
| 26 | 53 | 50 | `lib/features/logs/presentation/widgets/time_field_widget.dart` |
| 27 | 175 | 165 | `lib/features/logs/presentation/widgets/time_picker_sheet.dart` |
| 28 | 168 | 157 | `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` |
| 29 | 183 | 170 | `lib/features/onboarding/presentation/pages/onboarding_page.dart` |
| 30 | 301 | 276 | `lib/features/permissions/presentation/pages/permissions_page.dart` |
| 31 | 214 | 202 | `lib/features/settings/presentation/pages/settings_page.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 60 | 53 | `lib/features/sync/data/datasources/sync_local_data_source.dart` |
| 2 | 56 | 52 | `lib/features/sync/data/models/sync_item_model.dart` |
| 3 | 148 | 132 | `lib/features/sync/data/providers/sync_providers.dart` |
| 4 | 145 | 128 | `lib/features/sync/data/repositories/memory_offline_queue.dart` |
| 5 | 382 | 355 | `lib/features/sync/data/repositories/sqlite_offline_queue.dart` |
| 6 | 156 | 139 | `lib/features/sync/data/repositories/sync_repository_impl.dart` |
| 7 | 322 | 300 | `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 19 | 16 | `lib/features/sync/domain/entities/dispatch_auth.dart` |
| 2 | 109 | 91 | `lib/features/sync/domain/entities/event_ownership.dart` |
| 3 | 72 | 63 | `lib/features/sync/domain/entities/pending_event.dart` |
| 4 | 41 | 35 | `lib/features/sync/domain/entities/quarantine_record.dart` |
| 5 | 100 | 90 | `lib/features/sync/domain/entities/sync_item.dart` |
| 6 | 49 | 38 | `lib/features/sync/domain/repositories/offline_queue.dart` |
| 7 | 25 | 19 | `lib/features/sync/domain/repositories/sync_repository.dart` |
| 8 | 226 | 209 | `lib/features/sync/domain/usecases/sync_engine.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 4 | 4 | `lib/features/sync/presentation/providers/sync_engine_provider.dart` |
| 2 | 76 | 64 | `lib/features/sync/presentation/providers/sync_provider.dart` |
| 3 | 46 | 42 | `lib/features/sync/presentation/widgets/sync_status_indicator.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 168 | 139 | `lib/features/tracking/data/datasources/live_tracking_data_source.dart` |
| 2 | 164 | 142 | `lib/features/tracking/data/datasources/native_event_channel_client.dart` |
| 3 | 135 | 117 | `lib/features/tracking/data/datasources/traccar_data_source.dart` |
| 4 | 30 | 22 | `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart` |
| 5 | 19 | 15 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart` |
| 6 | 131 | 122 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart` |
| 7 | 24 | 18 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart` |
| 8 | 79 | 71 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart` |
| 9 | 21 | 16 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client.dart` |
| 10 | 156 | 136 | `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client_impl.dart` |
| 11 | 26 | 20 | `lib/features/tracking/data/datasources/tracking_data_source.dart` |
| 12 | 69 | 56 | `lib/features/tracking/data/datasources/tracking_local_data_source.dart` |
| 13 | 59 | 55 | `lib/features/tracking/data/models/location_model.dart` |
| 14 | 51 | 45 | `lib/features/tracking/data/providers/tracking_providers.dart` |
| 15 | 243 | 222 | `lib/features/tracking/data/repositories/tracking_repository_impl.dart` |
| 16 | 204 | 180 | `lib/features/tracking/data/services/tracking_service.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 8 | 8 | `lib/features/tracking/domain/entities/connection_status.dart` |
| 2 | 141 | 128 | `lib/features/tracking/domain/entities/location_entity.dart` |
| 3 | 75 | 69 | `lib/features/tracking/domain/entities/native_location_event.dart` |
| 4 | 98 | 93 | `lib/features/tracking/domain/entities/tracking_event.dart` |
| 5 | 8 | 7 | `lib/features/tracking/domain/repositories/tracking_data_source_port.dart` |
| 6 | 36 | 26 | `lib/features/tracking/domain/repositories/tracking_repository.dart` |
| 7 | 124 | 107 | `lib/features/tracking/domain/usecases/tracking_event_processor.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 252 | 220 | `lib/features/tracking/presentation/providers/tracking_provider.dart` |
| 2 | 15 | 13 | `lib/features/tracking/presentation/providers/tracking_providers.dart` |

### features/*/data

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 23 | 18 | `lib/features/vehicle/data/providers/vehicle_repository_providers.dart` |
| 2 | 81 | 74 | `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart` |

### features/*/domain

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 68 | 62 | `lib/features/vehicle/domain/entities/vehicle.dart` |
| 2 | 15 | 12 | `lib/features/vehicle/domain/repositories/vehicle_repository.dart` |
| 3 | 153 | 142 | `lib/features/vehicle/domain/vehicle_selection.dart` |

### features/*/presentation

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 299 | 285 | `lib/features/vehicle/presentation/pages/select_vehicle_page.dart` |
| 2 | 254 | 227 | `lib/features/vehicle/presentation/providers/vehicle_provider.dart` |
| 3 | 124 | 118 | `lib/features/vehicle/presentation/widget/vehicle_card.dart` |

### app / routes / root

| # | Lines | NonEmpty | Path |
|---|---|---|---|
| 1 | 5814 | 4853 | `lib/l10n/app_localizations.dart` *(Gen — excluded)* |
| 2 | 3044 | 2096 | `lib/l10n/app_localizations_ar.dart` *(Gen — excluded)* |
| 3 | 3063 | 2115 | `lib/l10n/app_localizations_en.dart` *(Gen — excluded)* |
| 4 | 3090 | 2142 | `lib/l10n/app_localizations_es.dart` *(Gen — excluded)* |
| 5 | 64 | 54 | `lib/main.dart` |
| 6 | 100 | 86 | `lib/routes.dart` |
| 7 | 46 | 44 | `lib/routes/account_routes.dart` |
| 8 | 39 | 37 | `lib/routes/auth_routes.dart` |
| 9 | 33 | 31 | `lib/routes/dvir_routes.dart` |
| 10 | 38 | 36 | `lib/routes/home_routes.dart` |
| 11 | 43 | 41 | `lib/routes/logs_routes.dart` |

