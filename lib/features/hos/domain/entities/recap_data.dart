import 'package:equatable/equatable.dart';

class DailyRecap extends Equatable {
  final DateTime date;
  final double hoursWorked;
  final String dayName;
  final String formattedDate;

  const DailyRecap({
    required this.date,
    required this.hoursWorked,
    required this.dayName,
    required this.formattedDate,
  });

  @override
  List<Object?> get props => [date, hoursWorked, dayName, formattedDate];
}

class RecapData extends Equatable {
  final List<DailyRecap> last7Days; // Should contain exactly 7 days
  final double totalLast7Days;
  final double hoursWorkedToday;
  final double hoursAvailableToday;
  final double hoursAvailableTomorrow;

  const RecapData({
    required this.last7Days,
    required this.totalLast7Days,
    required this.hoursWorkedToday,
    required this.hoursAvailableToday,
    required this.hoursAvailableTomorrow,
  });

  factory RecapData.empty() {
    return const RecapData(
      last7Days: [],
      totalLast7Days: 0,
      hoursWorkedToday: 0,
      hoursAvailableToday: 0,
      hoursAvailableTomorrow: 0,
    );
  }

  @override
  List<Object?> get props => [
        last7Days,
        totalLast7Days,
        hoursWorkedToday,
        hoursAvailableToday,
        hoursAvailableTomorrow,
      ];
}
