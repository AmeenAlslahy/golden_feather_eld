#!/bin/bash
echo "=== 1. git log --oneline -15 ==="
git log --oneline -15

echo "=== 2. git show --stat HEAD ==="
git show --stat HEAD

echo "=== 3. git diff HEAD~1 ==="
echo "Count:"
git diff HEAD~1 --name-only | wc -l
echo "Files outside core/backend/domain/test/helpers:"
git diff HEAD~1 --name-only | grep -v "^lib/backend" | grep -v "^lib/core" | grep -v "^lib/domain" | grep -v "^test/helpers" | head -30

echo "=== 4. cat analysis_options.yaml ==="
cat analysis_options.yaml

echo "=== 5. cat pubspec.yaml ==="
cat pubspec.yaml

echo "=== 6. flutter pub get ==="
flutter pub get 2>&1 | tail -5

echo "=== 7. flutter analyze ==="
flutter analyze 2>&1 | tail -40

echo "=== 8. dart analyze lib/backend/ test/helpers/ ==="
dart analyze lib/backend/ test/helpers/ 2>&1 | tail -20

echo "=== 9. cat test/helpers/test_helpers.dart ==="
cat test/helpers/test_helpers.dart

echo "=== 10. ls -la lib/backend/providers/ ==="
ls -la lib/backend/providers/
