import '../../domain/entities/daily_log.dart';

/// بيانات وهمية للسجلات
class LogsMockData {
  static List<DailyLog> getLogs() {
    final now = DateTime.now();
    return [
      // اليوم
      DailyLog(
        id: '1',
        date: now,
        totalDrivingHours: 10.92,
        isFormComplete: true,
        isCertified: true,
        events: _generateEvents(now),
      ),
      // أمس
      DailyLog(
        id: '2',
        date: now.subtract(const Duration(days: 1)),
        totalDrivingHours: 8.25,
        isFormComplete: true,
        isCertified: true,
        events: _generateEvents(now.subtract(const Duration(days: 1))),
      ),
      // قبل يومين
      DailyLog(
        id: '3',
        date: now.subtract(const Duration(days: 2)),
        totalDrivingHours: 11.00,
        isFormComplete: false,
        isCertified: true,
        events: _generateEvents(now.subtract(const Duration(days: 2))),
      ),
      // باقي الأيام
      for (int i = 3; i < 7; i++)
        DailyLog(
          id: '${i + 1}',
          date: now.subtract(Duration(days: i)),
          totalDrivingHours: 5.0 + (i * 1.5),
          isFormComplete: i % 2 == 0,
          isCertified: i != 4,
          events: _generateEvents(now.subtract(Duration(days: i))),
        ),
    ];
  }

  static List<LogEvent> _generateEvents(DateTime date) {
    // إنشاء بيانات مختلفة بناءً على اليوم لإظهار تفاعل المخطط الزمني
    if (date.day % 3 == 0) {
      return [
        LogEvent(
          id: '${date.day}_1',
          status: 'SB',
          statusArabic: 'النوم',
          startTime: DateTime(date.year, date.month, date.day, 0, 0),
          duration: const Duration(hours: 10, minutes: 0),
          location: 'Tulum, MX',
          odometer: 125000.0,
          engineHours: 3500.0,
        ),
        LogEvent(
          id: '${date.day}_2',
          status: 'ON',
          statusArabic: 'على أهبة العمل',
          startTime: DateTime(date.year, date.month, date.day, 10, 0),
          duration: const Duration(hours: 1, minutes: 30),
          location: 'Tulum, MX',
          odometer: 125000.0,
          engineHours: 3501.5,
        ),
        LogEvent(
          id: '${date.day}_3',
          status: 'D',
          statusArabic: 'قيادة',
          startTime: DateTime(date.year, date.month, date.day, 11, 30),
          duration: const Duration(hours: 9, minutes: 15),
          location: 'Merida, MX',
          odometer: 125500.0,
          engineHours: 3510.75,
        ),
        LogEvent(
          id: '${date.day}_4',
          status: 'OFF',
          statusArabic: 'خارج الخدمة',
          startTime: DateTime(date.year, date.month, date.day, 20, 45),
          duration: const Duration(hours: 3, minutes: 15),
          location: 'Merida, MX',
          odometer: 125500.0,
          engineHours: 3510.75,
        ),
      ];
    } else if (date.day % 2 == 0) {
      return [
        LogEvent(
          id: '${date.day}_1',
          status: 'OFF',
          statusArabic: 'خارج الخدمة',
          startTime: DateTime(date.year, date.month, date.day, 0, 0),
          duration: const Duration(hours: 6, minutes: 45),
          location: 'Cancun, MX',
          odometer: 126000.0,
          engineHours: 3600.0,
        ),
        LogEvent(
          id: '${date.day}_2',
          status: 'D',
          statusArabic: 'قيادة',
          startTime: DateTime(date.year, date.month, date.day, 6, 45),
          duration: const Duration(hours: 4, minutes: 0),
          location: 'Playa del Carmen, MX',
          odometer: 126200.0,
          engineHours: 3604.0,
        ),
        LogEvent(
          id: '${date.day}_3',
          status: 'SB',
          statusArabic: 'النوم',
          startTime: DateTime(date.year, date.month, date.day, 10, 45),
          duration: const Duration(hours: 2, minutes: 30),
          location: 'Playa del Carmen, MX',
          odometer: 126200.0,
          engineHours: 3604.0,
        ),
        LogEvent(
          id: '${date.day}_4',
          status: 'D',
          statusArabic: 'قيادة',
          startTime: DateTime(date.year, date.month, date.day, 13, 15),
          duration: const Duration(hours: 5, minutes: 0),
          location: 'Chetumal, MX',
          odometer: 126500.0,
          engineHours: 3609.0,
        ),
        LogEvent(
          id: '${date.day}_5',
          status: 'OFF',
          statusArabic: 'خارج الخدمة',
          startTime: DateTime(date.year, date.month, date.day, 18, 15),
          duration: const Duration(hours: 5, minutes: 45),
          location: 'Chetumal, MX',
          odometer: 126500.0,
          engineHours: 3609.0,
        ),
      ];
    }
    
    // النمط الافتراضي للأيام الفردية الأخرى
    return [
      LogEvent(
        id: '${date.day}_1',
        status: 'OFF',
        statusArabic: 'خارج الخدمة',
        startTime: DateTime(date.year, date.month, date.day, 0, 0),
        duration: const Duration(hours: 8, minutes: 15),
        location: '16mi SSW from Isla Mujeres, Quintana Roo, MX',
        odometer: 125000.0,
        engineHours: 3500.0,
      ),
      LogEvent(
        id: '${date.day}_2',
        status: 'SB',
        statusArabic: 'النوم',
        startTime: DateTime(date.year, date.month, date.day, 8, 15),
        duration: const Duration(minutes: 30),
        location: '12mi NE from Cancun, Quintana Roo, MX',
        odometer: 125012.0,
        engineHours: 3500.5,
      ),
      LogEvent(
        id: '${date.day}_3',
        status: 'D',
        statusArabic: 'قيادة',
        startTime: DateTime(date.year, date.month, date.day, 8, 45),
        duration: const Duration(hours: 5, minutes: 30),
        location: '25mi SW from Playa del Carmen, MX',
        odometer: 125080.0,
        engineHours: 3506.0,
      ),
      LogEvent(
        id: '${date.day}_4',
        status: 'ON',
        statusArabic: 'على أهبة العمل',
        startTime: DateTime(date.year, date.month, date.day, 14, 15),
        duration: const Duration(hours: 1, minutes: 45),
        location: '8mi NW from Tulum, Quintana Roo, MX',
        odometer: 125090.0,
        engineHours: 3507.75,
      ),
      LogEvent(
        id: '${date.day}_5',
        status: 'D',
        statusArabic: 'قيادة',
        startTime: DateTime(date.year, date.month, date.day, 16, 0),
        duration: const Duration(hours: 4, minutes: 22),
        location: '30mi NE from Chetumal, MX',
        odometer: 125150.0,
        engineHours: 3512.0,
      ),
    ];
  }
}



