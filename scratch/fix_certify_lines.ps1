$filePath = "d:\Flutter projects\golden_feather_eld\test\core\engine\tracking\duty_status_tracker_test.dart"
$content = Get-Content $filePath
$newContent = @()
for ($i = 0; $i -lt $content.Count; $i++) {
    if ($i -ge 102 -and $i -le 107) {
        continue
    }
    if ($i -eq 108) {
        $newContent += "  Future<Either<Failure, bool>> certifyLog({"
        $newContent += "    required DailyLogId logId,"
        $newContent += "    required String signatureCertificateId,"
        $newContent += "    required bool signatureConfirmation,"
        $newContent += "    required bool certifiedTrue,"
        $newContent += "    required int driverId,"
        $newContent += "    required String logDate,"
        $newContent += "  }) async {"
        continue
    }
    $newContent += $content[$i]
}
$newContent | Set-Content $filePath
