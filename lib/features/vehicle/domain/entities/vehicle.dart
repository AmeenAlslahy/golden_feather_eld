import 'package:equatable/equatable.dart';

/// كيان المركبة
class Vehicle extends Equatable {
  final String id;
  final String name;
  final String year;
  final String? type;
  final String? vin;
  final String? trailerId;
  final bool isAssigned;

  const Vehicle({
    required this.id,
    required this.name,
    required this.year,
    this.type,
    this.vin,
    this.trailerId,
    this.isAssigned = true,
  });

  String get displayName => '$id | $year $name';
  
  String get shortDisplayName => '$id - $name';

  @override
  List<Object?> get props => [id, name, year, type, vin, trailerId, isAssigned];
}
