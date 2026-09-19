New-Item -ItemType Directory -Force -Path docs/api
$out = "docs/api/swagger_probe.txt"

"=== 1. Get swagger.json ===" > $out
curl.exe -sS -o docs/api/swagger_1.json -w "%{http_code}\n" https://snsoft.cloud/api/swagger.json >> $out
curl.exe -sS -o docs/api/swagger_2.json -w "%{http_code}\n" https://snsoft.cloud/api/v3/api-docs >> $out
curl.exe -sS -o docs/api/swagger_3.json -w "%{http_code}\n" https://snsoft.cloud/api/v3/api-docs/eld >> $out
curl.exe -sS -o docs/api/swagger_4.json -w "%{http_code}\n" https://snsoft.cloud/api/eld/openapi.yaml >> $out

"=== 2. Valid 200 files ===" >> $out
foreach ($i in 1..4) {
    $f = "docs/api/swagger_$i.json"
    if (Test-Path $f) {
        $size = (Get-Item $f).length
        if ($size -gt 0) {
            "=== $f ===" >> $out
            Get-Content $f -TotalCount 20 >> $out
            "" >> $out
            "Size: $size bytes" >> $out
        }
    }
}

"=== Spec URLs in Swagger UI HTML ===" >> $out
curl.exe -sS https://snsoft.cloud/api/swagger | Select-String -Pattern 'url:[^,]*|swagger[^"]*\.json|openapi[^"]*\.yaml' -AllMatches | % { $_.Matches } | % { $_.Value } | Select-Object -First 20 >> $out

"=== Login Probe ===" >> $out
curl.exe -sS -X POST -H "Content-Type: application/json" -d '{\"provider\":\"frontend\",\"loginAttribute\":\"email\",\"login\":\"test@test.com\",\"password\":\"test\"}' -w "\nHTTP: %{http_code}\n" https://snsoft.cloud/api/eld/profile/101 >> $out

"=== Health Probe ===" >> $out
curl.exe -sS -o NUL -w "Health: %{http_code}\n" https://snsoft.cloud/api/eld/health >> $out
curl.exe -sS -o NUL -w "Login: %{http_code}\n" https://snsoft.cloud/api/v1/auth/login >> $out

"=== Login paths in Swagger UI ===" >> $out
curl.exe -sS https://snsoft.cloud/api/swagger | Select-String -Pattern 'login|auth|token|signin' | Select-Object -First 20 >> $out
