/// Extension methods for integers representing time (usually minutes).
extension TimeExtensions on int {
  /// تحويل عدد الدقائق إلى سلسلة نصية بصيغة HH:MM
  String toHoursMinutes() {
    final hours = this ~/ 60;
    final minutes = this % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
