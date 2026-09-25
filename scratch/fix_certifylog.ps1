$filePath = "d:\Flutter projects\golden_feather_eld\test\core\engine\tracking\duty_status_tracker_test.dart"
$content = Get-Content $filePath
$newContent = @()
$skip = $false
for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    if ($line -match "Future<Either<Failure, bool>> certifyLog\(\{") {
        $skip = $true
        $newContent += "  @override"
        $newContent += "  Future<Either<Failure, bool>> certifyLog({"
        $newContent += "    required DailyLogId logId,"
        $newContent += "    required String signatureCertificateId,"
        $newContent += "    required bool signatureConfirmation,"
        $newContent += "    required bool certifiedTrue,"
        $newContent += "    required int driverId,"
        $newContent += "    required String logDate,"
        $newContent += "  }) async {"
        $newContent += "    return const Right(true);"
        $newContent += "  }"
    } elseif ($skip -and $line -match "^\s*\}\s*$") {
        # this is the end of the method we are skipping
        $skip = $false
        # but wait, the method ends at `  }`, let's just skip lines until `  }` is found
    } elseif (-not $skip) {
        $newContent += $line
    }
}
$newContent | Set-Content $filePath
