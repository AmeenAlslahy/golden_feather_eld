import 'dart:io';
import 'dart:convert';

void main() async {
  final dir = Directory('lib');
  final testDir = Directory('test');
  
  final allLibFiles = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  final allTestFiles = testDir.existsSync() ? testDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList() : <File>[];
  
  int traccarMentions = 0;
  List<String> traccarFiles = [];
  Map<String, int> typeCounts = {};
  List<Map<String, dynamic>> coverageData = [];

  for (var file in allLibFiles) {
    final path = file.path.replaceAll('\\', '/');
    final content = file.readAsStringSync();
    
    // Type classification
    String type = 'Other';
    if (path.contains('presentation/widgets') || path.contains('presentation/components')) type = 'UI Widgets';
    else if (path.contains('presentation/pages') || path.contains('presentation/screens')) type = 'Screens / Pages';
    else if (path.contains('presentation/providers') || path.contains('application') || path.contains('state')) type = 'Riverpod Providers';
    else if (path.contains('domain/entities') || path.contains('domain/models')) type = 'Domain Models';
    else if (path.contains('domain/repositories')) type = 'Repositories';
    else if (path.contains('infrastructure/data_sources') || path.contains('data/datasources')) type = 'Data Sources';
    else if (path.contains('domain/usecases') || path.contains('engines')) type = 'Engines / Use Cases';
    
    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    
    // Test coverage check
    String testPath = path.replaceFirst('lib/', 'test/').replaceFirst('.dart', '_test.dart');
    bool hasTest = allTestFiles.any((f) => f.path.replaceAll('\\', '/') == testPath);
    
    // Traccar coupling
    if (content.toLowerCase().contains('traccar')) {
      traccarMentions++;
      traccarFiles.add(path);
    }
    
    coverageData.add({
      'path': path,
      'type': type,
      'hasTest': hasTest,
      'traccar': content.toLowerCase().contains('traccar'),
    });
  }

  // Quick stats output
  final stats = {
    'total_files': allLibFiles.length,
    'total_tests': allTestFiles.length,
    'traccar_coupled_files': traccarFiles,
    'type_counts': typeCounts,
    'coverage': coverageData,
  };
  
  File('audit_stats.json').writeAsStringSync(jsonEncode(stats));
  print('Audit script finished.');
}
