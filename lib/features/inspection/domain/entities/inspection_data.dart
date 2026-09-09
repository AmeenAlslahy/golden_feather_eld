import 'package:equatable/equatable.dart';

/// بيانات التفتيش
class InspectionDayData extends Equatable {
  final DateTime date;
  final double drivingHours;
  final double onDutyHours;
  final double offDutyHours;
  final double sleeperHours;
  final bool isCertified;

  const InspectionDayData({
    required this.date,
    required this.drivingHours,
    required this.onDutyHours,
    required this.offDutyHours,
    required this.sleeperHours,
    this.isCertified = false,
  });

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  List<Object?> get props => [
        date,
        drivingHours,
        onDutyHours,
        offDutyHours,
        sleeperHours,
        isCertified
      ];
}

/// طريقة نقل البيانات
enum TransferMethod {
  webService('Web Service', 'خدمة الويب'),
  email('Email', 'بريد إلكتروني'),
  bluetooth('Bluetooth', 'بلوتوث'),
  usb('USB', 'USB');

  final String englishName;
  final String arabicName;
  const TransferMethod(this.englishName, this.arabicName);
}
