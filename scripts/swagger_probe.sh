#!/bin/bash

mkdir -p docs/api

# 1. محاولات للحصول على swagger.json
curl -sS -o /tmp/swagger_1.json -w "%{http_code}\n" \
  https://snsoft.cloud/api/swagger.json

curl -sS -o /tmp/swagger_2.json -w "%{http_code}\n" \
  https://snsoft.cloud/api/v3/api-docs

curl -sS -o /tmp/swagger_3.json -w "%{http_code}\n" \
  https://snsoft.cloud/api/v3/api-docs/eld

curl -sS -o /tmp/swagger_4.json -w "%{http_code}\n" \
  https://snsoft.cloud/api/eld/openapi.yaml

# 2. اختر الملف الذي أعاد 200
for f in /tmp/swagger_*.json; do
  if [ -s "$f" ]; then
    echo "=== $f ==="
    head -20 "$f"
    echo ""
    echo "Size: $(wc -c < $f) bytes"
  fi
done

# 3. ابحث في HTML لـ swagger UI عن URL الـ spec
echo "=== Spec URLs in Swagger UI HTML ==="
curl -sS https://snsoft.cloud/api/swagger | \
  grep -oE 'url:[^,]*|swagger[^"]*\.json|openapi[^"]*\.yaml' | head -20

# 4. جرّب endpoint الـ login
echo "=== Login Probe ==="
curl -sS -X POST \
  -H "Content-Type: application/json" \
  -d '{"provider":"frontend","loginAttribute":"email","login":"test@test.com","password":"test"}' \
  -w "\nHTTP: %{http_code}\n" \
  https://snsoft.cloud/api/eld/profile/101

# 5. تحقق من health
echo "=== Health Probe ==="
curl -sS -o /dev/null -w "Health: %{http_code}\n" \
  https://snsoft.cloud/api/eld/health

curl -sS -o /dev/null -w "Login: %{http_code}\n" \
  https://snsoft.cloud/api/v1/auth/login

# 6. اكتشف مسار الـ login من الـ Swagger
echo "=== Login paths in Swagger UI ==="
curl -sS https://snsoft.cloud/api/swagger | \
  grep -iE 'login|auth|token|signin' | head -20
