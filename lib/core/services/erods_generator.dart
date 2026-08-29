/// مولد ملفات eRODS القياسية وفق متطلبات FMCSA
class ErodsGenerator {
  /// توليد ملف eRODS بصيغة XML
  static String generateErodsXml(Map<String, dynamic> reportData) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<eRODS>');
    
    // Header
    buffer.writeln('  <Header>');
    buffer.writeln('    <DriverName>${_escapeXml(reportData['driver']?['name'])}</DriverName>');
    buffer.writeln('    <VehicleID>${_escapeXml(reportData['driver']?['vehicle_id'])}</VehicleID>');
    buffer.writeln('    <Date>${_escapeXml(reportData['date'])}</Date>');
    buffer.writeln('    <GeneratedAt>${_escapeXml(reportData['generated_at'])}</GeneratedAt>');
    buffer.writeln('  </Header>');
    
    // Events
    buffer.writeln('  <Events>');
    final events = reportData['events'] as List<dynamic>? ?? [];
    for (var event in events) {
      buffer.writeln('    <Event>');
      buffer.writeln('      <Time>${_escapeXml(event['time'])}</Time>');
      buffer.writeln('      <Status>${_escapeXml(event['status'])}</Status>');
      buffer.writeln('    </Event>');
    }
    buffer.writeln('  </Events>');
    
    // Diagnostics
    buffer.writeln('  <Diagnostics>');
    final diagnostics = reportData['diagnostics'] as List<dynamic>? ?? [];
    for (var d in diagnostics) {
      buffer.writeln('    <Diagnostic>');
      buffer.writeln('      <Type>${_escapeXml(d['type'])}</Type>');
      buffer.writeln('      <Severity>${_escapeXml(d['severity'])}</Severity>');
      buffer.writeln('      <Message>${_escapeXml(d['message'])}</Message>');
      buffer.writeln('    </Diagnostic>');
    }
    buffer.writeln('  </Diagnostics>');
    
    buffer.writeln('</eRODS>');
    
    return buffer.toString();
  }

  /// توليد ملف eRODS بصيغة CSV
  static String generateErodsCsv(Map<String, dynamic> reportData) {
    final buffer = StringBuffer();
    
    buffer.writeln('Driver Name,Vehicle ID,Date,Generated At');
    buffer.writeln('${_escapeCsv(reportData['driver']?['name'])},${_escapeCsv(reportData['driver']?['vehicle_id'])},${_escapeCsv(reportData['date'])},${_escapeCsv(reportData['generated_at'])}');
    
    buffer.writeln('\nEvents');
    buffer.writeln('Time,Status');
    final events = reportData['events'] as List<dynamic>? ?? [];
    for (var event in events) {
      buffer.writeln('${_escapeCsv(event['time'])},${_escapeCsv(event['status'])}');
    }
    
    buffer.writeln('\nDiagnostics');
    buffer.writeln('Type,Severity,Message');
    final diagnostics = reportData['diagnostics'] as List<dynamic>? ?? [];
    for (var d in diagnostics) {
      buffer.writeln('${_escapeCsv(d['type'])},${_escapeCsv(d['severity'])},${_escapeCsv(d['message'])}');
    }
    
    return buffer.toString();
  }

  static String _escapeXml(dynamic value) {
    if (value == null) return '';
    return value.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _escapeCsv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
