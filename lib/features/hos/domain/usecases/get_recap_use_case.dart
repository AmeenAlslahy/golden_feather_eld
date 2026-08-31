import 'package:intl/intl.dart';
import '../../../../core/engine/hos_models.dart';
import '../../../../core/engine/hos_calculator.dart';
import '../../../logs/domain/repositories/log_repository.dart';
import '../entities/recap_data.dart';
import '../../../../core/utils/logger.dart';

class GetRecapUseCase {
  final LogRepository _logRepository;

  GetRecapUseCase(this._logRepository);

  Future<RecapData> execute({
    required HosLimits currentLimits,
    required double cycleLimitHours,
  }) async {
    final now = DateTime.now();
    final last7Days = <DailyRecap>[];
    double totalLast7Days = 0.0;

    // Fetch data for the last 7 days concurrently
    final periodFutures = <Future>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      periodFutures.add(_logRepository.getPeriods(date));
    }

    final results = await Future.wait(periodFutures);

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final periodsResult = results[6 - i];
      
      double hoursWorked = 0.0;
      
      periodsResult.match(
        (failure) {
          AppLogger.error('Failed to fetch recap for $date: ${failure.message}');
        },
        (periods) {
          for (var period in periods) {
            if (period.status == DutyStatus.driving.name || period.status == DutyStatus.onDutyNotDriving.name) {
              hoursWorked += period.duration.inMinutes / 60.0;
            }
          }
        },
      );

      last7Days.add(DailyRecap(
        date: date,
        hoursWorked: hoursWorked,
        dayName: DateFormat('EEEE').format(date),
        formattedDate: DateFormat('MMM d').format(date),
      ));

      totalLast7Days += hoursWorked;
    }

    // Today's worked hours is the last item in the list
    final hoursWorkedToday = last7Days.last.hoursWorked;

    // Available today comes from the engine's limits
    final availableToday = currentLimits.remainingCycleHours; 

    // Available tomorrow = CycleLimit - (total of last 6 days) - today - tomorrow's worked (0 so far)
    final oldestDayHours = last7Days.first.hoursWorked;
    
    final hoursAvailableTomorrow = (cycleLimitHours - (totalLast7Days - oldestDayHours)).clamp(0.0, cycleLimitHours);

    return RecapData(
      last7Days: last7Days,
      totalLast7Days: totalLast7Days,
      hoursWorkedToday: hoursWorkedToday,
      hoursAvailableToday: availableToday,
      hoursAvailableTomorrow: hoursAvailableTomorrow,
    );
  }
}
