import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/engine/hos_models.dart';
import '../../../../core/engine/hos_calculator.dart';
import '../../../logs/data/repositories/log_repository_impl.dart';
import '../../domain/entities/recap_data.dart';
import 'hos_provider.dart';

final recapProvider = FutureProvider<RecapData>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final hosStatus = ref.watch(hosStatusProvider);
  
  final now = DateTime.now();
  final last7Days = <DailyRecap>[];
  double totalLast7Days = 0.0;

  // Fetch data for the last 7 days (including today as the 7th day, or the 6 past days + today)
  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final periodsResult = await logRepo.getPeriods(date);
    
    double hoursWorked = 0.0;
    
    periodsResult.match(
      (failure) {
        // Handle failure if needed, defaulting to 0.0
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
  // We use remainingCycleHours, or remainingShiftHours if it's smaller.
  final limits = hosStatus.limits;
  final availableToday = limits.remainingCycleHours; // The recap typically focuses on Cycle

  // Available tomorrow = CycleLimit - (total of last 6 days) - today - tomorrow's worked (0 so far)
  // Which is CycleLimit - (Total of last 7 days EXCEPT the oldest day)
  final oldestDayHours = last7Days.first.hoursWorked;
  final activeCycleHours = HosCalculator.activeMaxCycleHours.toDouble();
  
  // Hours available tomorrow is active limit minus what will be in the last 7 days tomorrow
  // Tomorrow, today's "oldest day" (6 days ago) will fall off.
  // So the days that count against tomorrow's cycle are day 1 to day 6, which is (totalLast7Days - oldestDayHours).
  final hoursAvailableTomorrow = (activeCycleHours - (totalLast7Days - oldestDayHours)).clamp(0.0, activeCycleHours);

  return RecapData(
    last7Days: last7Days,
    totalLast7Days: totalLast7Days,
    hoursWorkedToday: hoursWorkedToday,
    hoursAvailableToday: availableToday,
    hoursAvailableTomorrow: hoursAvailableTomorrow,
  );
});
