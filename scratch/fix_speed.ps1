$filePath = "d:\Flutter projects\golden_feather_eld\test\core\engine\tracking\duty_status_tracker_test.dart"
$content = Get-Content $filePath
$newContent = $content | ForEach-Object {
    if ($_ -match "speed: Speed.fromMilesPerHour\((.+?)\)") {
        $speedVal = $matches[1]
        $_ -replace "speed: Speed.fromMilesPerHour\((.+?)\)", "speedMph: $speedVal"
    } else {
        $_
    }
}
$newContent | Set-Content $filePath
