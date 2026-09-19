# Architecture Overview

## 5 Layers + 1 Rule
┌──────────────────────────────────────────┐
│ app/ │ ← Composition Root
│ main.dart, app.dart, router.dart │ (يستورد من الكل)
└────────────────┬─────────────────────────┘
│
┌────────────────▼─────────────────────────┐
│ features/<name>/ │ ← UI + Feature Logic
│ presentation/, data/ (opt), domain/ (opt)│
└────────────────┬─────────────────────────┘
│
┌────────────────▼─────────────────────────┐
│ backend/ │ ← الاتصال بالخادم
│ contracts/, adapters/, http/, core/ │
└────────────────┬─────────────────────────┘
│
┌────────────────▼─────────────────────────┐
│ domain/ │ ← نماذج العمل
│ user/, driver/, duty_status/, vehicle/ │
└────────────────┬─────────────────────────┘
│
┌────────────────▼─────────────────────────┐
│ core/ │ ← الأساسيات
│ error/, result/, time/, storage/ │
└──────────────────────────────────────────┘

## The Single Rule

> **الاستيراد ينزل فقط. لا يصعد. لا يمشي جانبيًا.**

### Allowed Matrix

| من | إلى | مسموح |
|---|---|---|
| `app/` | أي مكان | ✅ |
| `features/X/` | `backend/`, `domain/`, `core/` | ✅ |
| `backend/` | `domain/`, `core/` | ✅ |
| `domain/` | `core/` | ✅ |
| `core/` | — | ❌ |
| `domain/` | `backend/`, `features/` | ❌ |
| `backend/` | `features/` | ❌ |
| `features/X/` | `features/Y/` | ❌ |

## Layer Responsibilities

### `core/` — Foundation
- **يملك:** `AppError`, `Result`, `TimeAuthority`, Storage ports.
- **لا يعرف:** features, backend, domain.
- **Rule:** لا external imports عدا Flutter/Dart.

### `domain/` — Business Models
- **يملك:** Entities, Value Objects, domain enums.
- **يعرف:** `core/` فقط.
- **Rule:** Freezed + Equatable. لا JSON. لا Dio. لا Flutter widgets.

### `backend/` — Server Communication
- **يملك:** Contracts, Adapters, Mappers, HTTP.
- **يعرف:** `core/`, `domain/`.
- **Rule:** لا يعرف `features/`. لا يعرف UI.

### `features/<name>/` — Isolated Modules
- **يملك:** Presentation (pages, widgets, providers).
- **قد يملك:** Data (repositories) — **فقط عند وجود logic** (caching, offline queue).
- **قد يملك:** Domain (feature-specific entities) — فقط عند عدم الاستخدام عبر features.
- **Rule:** لا يرى features أخرى.

### `app/` — Composition Root
- يبني الـ ProviderContainer.
- يسجّل الـ routes.
- **لا يحوي logic.**

## When to Add a Feature Repository?

**Add a Repository only when:**
- Caching logic.
- Offline queue.
- Retry with backoff.
- Data transformation across multiple backends.

**Otherwise:** Provider → Backend directly.

## Enforcement

### Automated Check

```bash
bash scripts/check_architecture.sh
```

Checks for:
- `package:dio` imports outside `lib/backend/`.
- Upward imports (`core/` → anything, `domain/` → backend, etc.).
- Cross-feature imports.

Runs at:
- Pre-commit (local).
- CI (on PR).

## Rules Summary
1. Never import `package:dio` outside `lib/backend/`.
2. Never import `../features/` in `lib/core/`, `lib/domain/`, `lib/backend/`.
3. Never import `features/X/...` from `features/Y/...`.

## Directory Structure
```text
lib/
├── app/                       # Composition root
├── core/                      # Foundation
├── domain/                    # Business models
│   ├── shared/                # Value objects shared across domains
│   ├── user/
│   ├── driver/
│   ├── duty_status/
│   └── vehicle/
├── backend/                   # Server communication
│   ├── core/                  # Identity, Adapter, Registry
│   ├── contracts/             # 20 backend interfaces
│   ├── adapters/              # EldEngine + Mock implementations
│   ├── http/                  # ApiClient, interceptors
│   └── providers/             # Riverpod providers
└── features/                  # Isolated feature modules
    ├── hos/
    ├── logs/
    ├── dvir/
    └── ...
```

## References
- Backend contracts: `lib/backend/contracts/`.
- Backend Swagger: `/api/eld/openapi.yaml`.
- ADRs: `docs/adr/` (added per decision).
