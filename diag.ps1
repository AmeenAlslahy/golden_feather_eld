Write-Output "=== 1. git log --oneline -15 ==="
git log --oneline -15

Write-Output "=== 2. git show --stat HEAD ==="
git show --stat HEAD

Write-Output "=== 3. git diff HEAD~1 ==="
Write-Output "Count:"
(git diff HEAD~1 --name-only).Count
Write-Output "Files outside core/backend/domain/test/helpers:"
git diff HEAD~1 --name-only | Select-String -NotMatch "^lib/backend", "^lib/core", "^lib/domain", "^test/helpers" | Select-Object -First 30

Write-Output "=== 4. cat analysis_options.yaml ==="
Get-Content analysis_options.yaml | Out-String

Write-Output "=== 5. cat pubspec.yaml ==="
Get-Content pubspec.yaml | Out-String

Write-Output "=== 6. flutter pub get ==="
flutter pub get 2>&1 | Select-Object -Last 5

Write-Output "=== 7. flutter analyze ==="
flutter analyze 2>&1 | Select-Object -Last 40

Write-Output "=== 8. dart analyze lib/backend/ test/helpers/ ==="
dart analyze lib/backend/ test/helpers/ 2>&1 | Select-Object -Last 20

Write-Output "=== 9. cat test/helpers/test_helpers.dart ==="
Get-Content test\helpers\test_helpers.dart | Out-String

Write-Output "=== 10. ls -la lib/backend/providers/ ==="
Get-ChildItem -Path lib\backend\providers\ -Force
