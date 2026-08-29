import os
import re

def rep(filepath, pattern, replacement):
    filepath = os.path.join('d:/Flutter projects/golden_feather_eld', filepath)
    try:
        with open(filepath, 'r', encoding='utf-8') as f: content = f.read()
        new_content = re.sub(pattern, replacement, content, flags=re.DOTALL | re.MULTILINE)
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f: f.write(new_content)
            print(f'Updated {filepath}')
    except Exception as e:
        print(e)

rep('lib/core/services/local_storage_service.dart', r'return Right\(null\);', 'return const Right(null);')
rep('lib/core/services/local_storage_service.dart', r'case int:', 'case int _:')
rep('lib/core/services/local_storage_service.dart', r'case double:', 'case double _:')
rep('lib/core/services/local_storage_service.dart', r'case bool:', 'case bool _:')

rep('lib/core/theme/app_theme.dart', r'\.withOpacity\(', '.withValues(alpha: ')

rep('lib/features/auth/data/datasources/auth_local_data_source.dart', r'static const String _userKey', '// static const String _userKey')
rep('lib/features/auth/data/datasources/auth_local_data_source.dart', r'static const String _localPasswordKey', '// static const String _localPasswordKey')

rep('lib/features/auth/data/datasources/auth_remote_data_source.dart', r'return Right\(UserModel', 'return const Right(UserModel')

rep('lib/features/auth/data/repositories/auth_repository_impl.dart', r'return Right\(null\);', 'return const Right(null);')
rep('lib/features/auth/data/repositories/auth_repository_impl.dart', r'return Right\(\(\)\);', 'return const Right(());')

rep('lib/features/auth/presentation/pages/splash_page.dart', r"context\.go\('/login'\);", "if (mounted) context.go('/login');")
rep('lib/features/auth/presentation/pages/splash_page.dart', r"context\.go\('/home'\);", "if (mounted) context.go('/home');")
rep('lib/features/auth/presentation/pages/splash_page.dart', r"if \(mounted\) if \(mounted\)", "if (mounted)")

rep('lib/features/codriver/presentation/pages/codriver_page.dart', r'ScaffoldMessenger\.of\(context\)\.showSnackBar', 'if (mounted) ScaffoldMessenger.of(context).showSnackBar')

rep('lib/features/dvir/data/datasources/dvir_mock_data.dart', r'return Right\(\[', 'return const Right([')

rep('lib/features/hos/presentation/pages/hos_page.dart', r'const Expanded\(', 'Expanded(')

rep('lib/features/hos/presentation/widgets/main_circular_timer.dart', r'final strokeWidth = 12\.0;', 'const strokeWidth = 12.0;')
rep('lib/features/hos/presentation/widgets/main_circular_timer.dart', r'final size = 220\.0;', 'const size = 220.0;')

rep('lib/features/logs/presentation/pages/edit_log_page.dart', r'return Center\(child: CircularProgressIndicator\(\)\);', 'return const Center(child: CircularProgressIndicator());')

rep('lib/features/logs/presentation/pages/inspection_preview_page.dart', r'child: CircularProgressIndicator\(\)', 'child: const CircularProgressIndicator()')

rep('lib/features/logs/presentation/pages/log_detail_page.dart', r'void _showInspectionPreview\([^}]*\}', '')
rep('lib/features/logs/presentation/pages/log_detail_page.dart', r'final dashboard = ref\.watch\(dashboardProvider\);', '')
rep('lib/features/logs/presentation/pages/log_detail_page.dart', r'if \(mounted\) ScaffoldMessenger\.of\(context\)', '{ if (mounted) ScaffoldMessenger.of(context)')

rep('lib/features/sync/data/repositories/sync_repository_impl.dart', r'return Right\(null\);', 'return const Right(null);')

rep('lib/features/tracking/data/datasources/tracking_local_data_source.dart', r'final SharedPreferences _storage;', '// final SharedPreferences _storage;')

rep('lib/features/tracking/data/repositories/tracking_repository_impl.dart', r'return Right\(null\);', 'return const Right(null);')

rep('lib/routes.dart', r'class _PlaceholderPage .*?\}', '')

rep('test/haversine_distance_test.dart', r'final point', 'const point')
