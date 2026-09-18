Write-Output "=== 1. Backup & Reset ==="
git branch backup-2026-09-19-pre-surgical-fix
git reset --hard b28c149

Write-Output "=== 2. Remove api/ ==="
if (Test-Path api) { Remove-Item -Recurse -Force api }

Write-Output "=== 3. Commit ==="
git add -A
$commitMsg = @"
chore(api): remove legacy API documentation copies

Removed api/*.yaml — old documentation copies that should not
be relied upon.

Canonical source of truth:
- The backend's Swagger (served at /api/eld/openapi.yaml).
- Future: docs/api/openapi.yaml (locked snapshot).

Refs: cleanup
"@
git commit -m $commitMsg

Write-Output "=== 4. Flutter Setup ==="
flutter clean
flutter pub get

Write-Output "=== 5. flutter analyze ==="
flutter analyze 2>&1 | Select-Object -Last 5

Write-Output "=== 6. flutter test ==="
flutter test test/backend/ 2>&1 | Select-Object -Last 3

Write-Output "=== 7. git log ==="
git log --oneline -6

Write-Output "=== 8. git status ==="
git status
