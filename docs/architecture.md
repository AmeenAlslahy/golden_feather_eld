# Architecture Overview

## Layered Design
┌─────────────────────────────────────────┐
│ UI (features/*/presentation) │
│ — Flutter widgets, Riverpod providers │
│ — No HTTP, no Dio, no JSON │
└──────────────┬──────────────────────────┘
│ uses
▼
┌─────────────────────────────────────────┐
│ Domain (lib/domain/) │
│ — Canonical models (Freezed) │
│ — Value objects (UserId, DriverId...) │
│ — No external deps │
└──────────────▲──────────────────────────┘
│ contracts
│
┌──────────────┴──────────────────────────┐
│ Backend (lib/backend/) │
│ — 20 contracts │
│ — EldEngineAdapter + MockAdapter │
│ — HTTP layer (ApiClient) │
└──────────────┬──────────────────────────┘
│ uses
▼
┌─────────────────────────────────────────┐
│ Core (lib/core/) │
│ — AppError + Result │
│ — TimeAuthority, Storage ports │
│ — No feature imports │
└─────────────────────────────────────────┘

## Rules

1. **No feature → feature imports.** Via barrel files only.
2. **No core → features imports.**
3. **Backend is the only layer that knows Dio/JSON.**
4. **Domain has no external imports (besides Freezed).**
5. **Every method that can fail returns `Result<T>`.**

## Structure

| Path | Purpose |
|------|---------|
| `lib/core/` | Shared utilities (error, result, time, storage). |
| `lib/domain/` | Canonical domain models. |
| `lib/backend/` | Backend abstraction (contracts + adapters + HTTP). |
| `lib/features/` | Feature modules (isolated, barrel-exported). |
| `lib/app/` | Composition root (main, routing). |

## Backend Abstraction

- **Contracts**: 20 interfaces in `lib/backend/contracts/`.
- **Adapters**:
  - `EldEngineAdapter` — real HTTP calls to `/api/eld/*`.
  - `MockAdapter` — in-memory (development + tests).
- **Registry**: manages adapter switching at runtime.
- **HTTP**: `ApiClient` with envelope unwrap + error mapping.

## Testing

- **Unit tests** (domain, backend mappers): `test/backend/`, `test/core/`, `test/domain/`.
- **Widget tests**: `test/features/`.
- **Test helpers**: `test/helpers/test_helpers.dart`.

## References

- ADRs: `docs/adr/` (to be added in Phase 2).
- Swagger: `/api/eld/openapi.yaml` (source of truth for backend).
