import re

def replace_in_file(filepath, pattern, replacement):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f'Updated {filepath}')
    except Exception as e:
        print(f"Failed to process {filepath}: {e}")

# unused_import
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/home/presentation/widgets/eld_drawer.dart',
    r"import '../../../../core/services/password_service.dart';\n", "")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/inspection/presentation/pages/inspection_logs_page.dart',
    r"import '../../domain/entities/inspection_data.dart';\n", "")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/logs/presentation/pages/log_detail_page.dart',
    r"import 'package:golden_feather_eld/features/inspection/presentation/providers/inspection_provider.dart';\n", "")

# unused_element & variables
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/logs/presentation/pages/log_detail_page.dart',
    r"final dashboard = ref.watch\(dashboardProvider\);", "// final dashboard = ref.watch(dashboardProvider);")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/tracking/data/datasources/tracking_local_data_source.dart',
    r"final SharedPreferences _storage;", "// final SharedPreferences _storage;")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/auth/data/datasources/auth_local_data_source.dart',
    r"static const String _localPasswordKey = 'local_password';", "// static const String _localPasswordKey = 'local_password';")

# withOpacity -> withValues(alpha:)
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/inspection/presentation/pages/dot_inspection_page.dart',
    r"\.withOpacity\((.*?)\)", r".withValues(alpha: \1)")

# unnecessary const
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/hos/presentation/pages/hos_page.dart',
    r"const Expanded\(", "Expanded(")

# dead_null_aware_expression
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/logs/presentation/widgets/log_graph.dart',
    r"Theme\.of\(context\)\.colorScheme\.outlineVariant \?\? AppColors\.border", "Theme.of(context).colorScheme.outlineVariant")

# prefer_const_declarations
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/logs/presentation/widgets/log_graph.dart',
    r"final offsetX = 40\.0;", "const offsetX = 40.0;")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/hos/presentation/widgets/main_circular_timer.dart',
    r"final strokeWidth = 12\.0;", "const strokeWidth = 12.0;")
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/hos/presentation/widgets/main_circular_timer.dart',
    r"final size = 220\.0;", "const size = 220.0;")
replace_in_file('d:/Flutter projects/golden_feather_eld/test/haversine_distance_test.dart',
    r"final point1 = ", "const point1 = ")
replace_in_file('d:/Flutter projects/golden_feather_eld/test/haversine_distance_test.dart',
    r"final point2 = ", "const point2 = ")

# use_build_context_synchronously
# In splash_page.dart
splash_fix = """if (mounted) {
      context.go('/login');
    }"""
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/auth/presentation/pages/splash_page.dart',
    r"context\.go\('/login'\);", splash_fix)
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/auth/presentation/pages/splash_page.dart',
    r"context\.go\('/home'\);", "if (mounted) { context.go('/home'); }")

# In log_detail_page.dart
replace_in_file('d:/Flutter projects/golden_feather_eld/lib/features/logs/presentation/pages/log_detail_page.dart',
    r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(", "if (mounted) ScaffoldMessenger.of(context).showSnackBar(")
