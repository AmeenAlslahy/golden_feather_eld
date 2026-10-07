import 'package:uuid/uuid.dart';

abstract class IdGenerator {
  String v4();
}

class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();
  
  @override
  String v4() => const Uuid().v4();
}
