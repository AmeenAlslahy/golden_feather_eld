Write-Output "=== 1. git show --stat 015a548 ==="
git show --stat 015a548

Write-Output "=== 2. git show --stat b28c149 ==="
git show --stat b28c149

Write-Output "=== 3. git log --oneline 6933d40..HEAD ==="
git log --oneline 6933d40..HEAD

Write-Output "=== 4. git status ==="
git status

Write-Output "=== 5. ls -la api/ ==="
Get-ChildItem -Path api/ -Force

Write-Output "=== 6. git log --oneline -5 -- api/ ==="
git log --oneline -5 -- api/

Write-Output "=== 7. head -30 api/duty-status.yaml ==="
Get-Content api\duty-status.yaml | Select-Object -First 30

Write-Output "=== 8. grep -rn 'unawaited_futures|depend_on_referenced_packages' analysis_options.yaml ==="
Select-String -Path analysis_options.yaml -Pattern "unawaited_futures|depend_on_referenced_packages"

Write-Output "=== 9. git show 015a548:analysis_options.yaml ==="
git show 015a548:analysis_options.yaml

Write-Output "=== 10. git show b28c149:analysis_options.yaml ==="
git show b28c149:analysis_options.yaml
