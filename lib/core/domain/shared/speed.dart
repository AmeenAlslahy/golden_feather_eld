import 'package:equatable/equatable.dart';

/// Value object representing Speed to avoid unit confusion (Knots vs MPH vs m/s).
class Speed extends Equatable implements Comparable<Speed> {
  final double metersPerSecond;

  const Speed._(this.metersPerSecond);

  /// Create from Meters per Second
  factory Speed.fromMetersPerSecond(double mps) {
    return Speed._(mps < 0 ? 0 : mps);
  }

  /// Create from Miles per Hour (1 mph = 0.44704 m/s)
  factory Speed.fromMilesPerHour(double mph) {
    return Speed._((mph < 0 ? 0 : mph) * 0.44704);
  }

  /// Create from Kilometers per Hour (1 km/h = 0.277778 m/s)
  factory Speed.fromKilometersPerHour(double kmh) {
    return Speed._((kmh < 0 ? 0 : kmh) * 0.277778);
  }

  /// Create from Knots (1 knot = 0.514444 m/s)
  factory Speed.fromKnots(double knots) {
    return Speed._((knots < 0 ? 0 : knots) * 0.514444);
  }

  double get inMetersPerSecond => metersPerSecond;
  double get inMilesPerHour => metersPerSecond * 2.23694;
  double get inKilometersPerHour => metersPerSecond * 3.6;
  double get inKnots => metersPerSecond * 1.94384;

  bool operator >(Speed other) => metersPerSecond > other.metersPerSecond;
  bool operator <(Speed other) => metersPerSecond < other.metersPerSecond;
  bool operator >=(Speed other) => metersPerSecond >= other.metersPerSecond;
  bool operator <=(Speed other) => metersPerSecond <= other.metersPerSecond;

  @override
  int compareTo(Speed other) {
    return metersPerSecond.compareTo(other.metersPerSecond);
  }

  @override
  List<Object?> get props => [metersPerSecond];

  @override
  String toString() => '${inMilesPerHour.toStringAsFixed(1)} mph';
}
