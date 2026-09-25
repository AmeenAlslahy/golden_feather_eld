$filePath = "d:\Flutter projects\golden_feather_eld\test\features\tracking\domain\usecases\tracking_event_processor_test.dart"
$content = Get-Content $filePath
$newContent = $content | ForEach-Object {
    $line = $_
    $line = $line -replace "\.speed\b", ".speedMph"
    $line = $line -replace "Speed\.fromMilesPerHour\((.+?)\)", "$1"
    $line
}
$newContent | Set-Content $filePath

$filePath2 = "d:\Flutter projects\golden_feather_eld\test\core\engine\tracking\duty_status_tracker_test.dart"
$content2 = Get-Content $filePath2
$newContent2 = $content2 | ForEach-Object {
    $line = $_
    $line = $line -replace "Speed\.fromMilesPerHour\((.+?)\)", "$1"
    $line
}
$newContent2 | Set-Content $filePath2
