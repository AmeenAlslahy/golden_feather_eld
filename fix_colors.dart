
import "dart:io";

void main() {
  final dir = Directory("lib/features");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith(".dart"));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    // Match and remove explicitly set textPrimary and textSecondary colors
    // Make sure to remove any trailing comma or preceding spaces if needed.
    // Easiest is just replacing `color: AppColors.textPrimary,` with ` `
    
    // Replace const TextStyle(color: ...) with TextStyle(...)
    content = content.replaceAll("const TextStyle(color: AppColors.textPrimary,", "TextStyle(");
    content = content.replaceAll("const TextStyle(color: AppColors.textSecondary,", "TextStyle(");
    
    content = content.replaceAll("color: AppColors.textPrimary,", "");
    content = content.replaceAll("color: AppColors.textPrimary", "");
    
    content = content.replaceAll("color: AppColors.textSecondary,", "");
    content = content.replaceAll("color: AppColors.textSecondary", "");
    
    content = content.replaceAll("backgroundColor: AppColors.background,", "");
    content = content.replaceAll("backgroundColor: AppColors.background", "");
    
    file.writeAsStringSync(content);
  }
}

