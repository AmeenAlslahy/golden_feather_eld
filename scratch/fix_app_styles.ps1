$libDir = "d:\Flutter projects\golden_feather_eld\lib"
$files = Get-ChildItem -Path $libDir -Filter "*.dart" -Recurse

foreach ($file in $files) {
    if ($file.Name -eq "app_text_styles.dart") { continue }
    
    $content = Get-Content $file.FullName
    $modified = $false

    $newContent = $content | ForEach-Object {
        $line = $_
        
        if ($line -match "context\.textStyles\.") {
            $line = $line -replace "context\.textStyles\.pageTitle", "context.styles.pageTitle"
            $line = $line -replace "context\.textStyles\.sectionTitle", "context.styles.sectionTitle"
            $line = $line -replace "context\.textStyles\.bodyBold", "context.styles.bodyBold"
            $line = $line -replace "context\.textStyles\.body", "context.styles.body"
            $line = $line -replace "context\.textStyles\.arabicBody", "context.styles.arabicBody"
            $line = $line -replace "context\.textStyles\.caption", "context.styles.caption"
            $line = $line -replace "context\.textStyles\.buttonText", "context.styles.button"
            $line = $line -replace "context\.textStyles\.goldText", "context.styles.gold"
            $line = $line -replace "context\.textStyles\.errorText", "context.styles.error"
            $line = $line -replace "context\.textStyles\.successText", "context.styles.success"
            $line = $line -replace "context\.textStyles\.warningText", "context.styles.warning"
            $line = $line -replace "context\.textStyles\.number", "context.styles.number"
            $modified = $true
        }

        if ($line -match "theme\.textStyles\(context\)\.") {
            $line = $line -replace "theme\.textStyles\(context\)\.pageTitle", "context.styles.pageTitle"
            $line = $line -replace "theme\.textStyles\(context\)\.sectionTitle", "context.styles.sectionTitle"
            $line = $line -replace "theme\.textStyles\(context\)\.bodyBold", "context.styles.bodyBold"
            $line = $line -replace "theme\.textStyles\(context\)\.body", "context.styles.body"
            $line = $line -replace "theme\.textStyles\(context\)\.arabicBody", "context.styles.arabicBody"
            $line = $line -replace "theme\.textStyles\(context\)\.caption", "context.styles.caption"
            $line = $line -replace "theme\.textStyles\(context\)\.buttonText", "context.styles.button"
            $line = $line -replace "theme\.textStyles\(context\)\.goldText", "context.styles.gold"
            $line = $line -replace "theme\.textStyles\(context\)\.errorText", "context.styles.error"
            $line = $line -replace "theme\.textStyles\(context\)\.successText", "context.styles.success"
            $line = $line -replace "theme\.textStyles\(context\)\.warningText", "context.styles.warning"
            $line = $line -replace "theme\.textStyles\(context\)\.number", "context.styles.number"
            $modified = $true
        }

        if ($line -match "import.*app_text_styles\.dart") {
            $line = ""
            $modified = $true
        }

        $line
    }

    if ($modified) {
        $newContent | Set-Content $file.FullName
    }
}

$themeFile = "d:\Flutter projects\golden_feather_eld\lib\core\theme\app_theme.dart"
$themeContent = Get-Content $themeFile
$newThemeContent = $themeContent | ForEach-Object {
    if ($_ -match "export 'app_text_styles.dart';") {
        ""
    } else {
        $_
    }
}
$newThemeContent | Set-Content $themeFile

Remove-Item "d:\Flutter projects\golden_feather_eld\lib\core\theme\app_text_styles.dart" -Force
